import ceylon.collection {
    HashMap,
    unlinked,
    Hashtable
}

import com.athaydes.concurrencey.internal {
    idCreator
}

import java.util.concurrent.atomic {
    AtomicInteger
}

"A computation result destination"
shared interface AcceptsValue<in Result> {
	"Sets the result of a computation"
	shared formal void set(Result|Exception result);
}

"A computation result source"
shared interface HasValue<out Result> {

	"Returns the result of a computation if this [[HasValue]] can provide it
	 immediately, or a [[NoValue]] otherwise."
	shared formal Result|Exception|NoValue getOrNoValue();
}

"A key which can be used to identify listeners, for example to retrieve or remove them."
see(`interface AsyncHasValue`)
shared interface ObserverId of ObserverIdImpl {
	"The key associated with the Observer" shared formal Integer key;
}

class ObserverIdImpl() satisfies ObserverId {
	shared actual Integer key = idCreator.createId();
	hash => key;
	shared actual Boolean equals(Object other) {
		if (is ObserverId other, other.key == key) {
			return true;
		}
		return false;
	}
}

"A computation result which can be accessed asynchronously."
shared interface AsyncHasValue<out Result> {

	"The given observer will be invoked on completion of the computation.
	 Many observers can be added.

	 Returns a [[ObserverId]] which may be used to stop observing."
	shared formal ObserverId onCompletion(Anything(Result|Exception) listener);

}

"Base class for Observable values."
see(`class WritableOncePromise`)
shared abstract class Observable<Result>(
	{<ObserverId->Anything(Result|Exception)>*} withObservers = {}) {

	value waitingNotify = HashMap<ObserverId, Anything(Result|Exception)>(unlinked,
		Hashtable{ initialCapacity = 4; }, withObservers);

	"A Sync which may be used to synchronize access the observers."
	shared Sync observersSync = Sync();

	"The observers observing this. For performance reasons, the returned map is
	 a read-only view of the internal map, not a copy."
	shared Map<ObserverId, Anything(Result|Exception)> observers = waitingNotify;

	"Observe this Observable."
	shared ObserverId observe(Anything(Result|Exception) listener) {
		value observerId = ObserverIdImpl();
		observersSync.syncExec(() => waitingNotify.put(observerId, listener));
		return observerId;
	}

	"Ensure the observer with the given ID is unregistered.

	 Returns true if and only if the observer was actually listening prior to this.
	 Notice that a write-only implementation might simply notify an Observer when it's added
	 without necessarily adding it to its internal map as that would be unnecessary. Removing
	 such observer would then return false."
	shared Boolean stopObserving(ObserverId observerId) {
		return observersSync.syncExec(() => waitingNotify.remove(observerId) exists);
	}

}

"A Promise represents the future result of a computation which may or may not
 ever complete, and may complete successfully or fail."
shared interface Promise<out Result>
		satisfies HasValue<Result> & AsyncHasValue<Result> {}

"A Writable version of [[Promise]]. The Result of a computation should be set only once.
 Trying to set the Result more than once will result in an [[Exception]] being thrown."
shared class WritableOncePromise<Result>(
	{<ObserverId->Anything(Result|Exception)>*} withListeners = {})
		extends Observable<Result>(withListeners)
		satisfies Promise<Result> & AcceptsValue<Result> {

	variable Result|Exception|NoValue result = noValue;
	value setterCount = AtomicInteger(0);

    "Number of times that the value of this promise has been attempted to be set."
	shared Integer attemptsToSet => setterCount.get();

	void setResultAndInformObservers(Result|Exception resultToSet) {
		this.result = resultToSet;
		for (observer in observers.items) {
			observer(resultToSet);
		}
	}

	"Set the result of the computation. This method can be called only once,
	 an Exception is thrown otherwise."
	throws(`class ForbiddenInvokationException`, "if the value of this promise has already been set")
	shared actual void set(Result|Exception resultToSet) {
		if (setterCount.getAndAdd(1) == 0) {
			observersSync.syncExec(() => setResultAndInformObservers(resultToSet));
		} else {
			throw ForbiddenInvokationException("The value of this WritableOncePromise has already been set");
		}
	}

	shared actual Result|Exception|NoValue getOrNoValue() {
		return result;
	}

	ObserverId addOrJustInformObserver(Anything(Result|Exception) observer) {
		value currentResult = result;
		if (is NoValue currentResult) {
			return observe(observer);
		}
		observer(currentResult);
		return ObserverIdImpl();
	}

	shared actual ObserverId onCompletion(Anything(Result|Exception) observer) {
		return observersSync.syncExec(() => addOrJustInformObserver(observer));
	}

}
