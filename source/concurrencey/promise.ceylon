import ceylon.collection {
	HashMap
}

import concurrencey.internal {
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
shared interface ListenerId of ListenerIdImpl {
	shared formal Integer key;
}

class ListenerIdImpl() satisfies ListenerId {
	shared actual Integer key = idCreator.createId();
	hash => key;
	shared actual Boolean equals(Object other) {
		if (is ListenerId other, other.key == key) {
			return true;
		}
		return false;
	}
}

"A computation result which can be accessed asynchronously."
shared interface AsyncHasValue<out Result> {
	
	"The given listener will be invoked on completion of the computation.
	 Many listeners can be added.
	 
	 Returns a [[ListenerId]] which can be used to stop listening."
	see(`function stopListening`)
	shared formal ListenerId onCompletion(Anything(Result|Exception) listener);
	
	"Unregister the listener with the given ID.
	 
	 Returns true if and only if the listener was actually listening prior to this."
	shared formal Boolean stopListening(ListenerId listenerId);
	
}

"A Promise represents the future result of a computation which may or may not
 ever complete, and may complete successfully or fail."
shared interface Promise<out Result>
		satisfies HasValue<Result> & AsyncHasValue<Result> {} 

"A Writable version of [[Promise]]. The Result of a computation should be set only once.
 Trying to set the Result more than once will result in an [[Exception]] being thrown."
shared class WritableOncePromise<Result>(
	{<ListenerId->Anything(Result|Exception)>*} withListeners = {})
		satisfies Promise<Result> & AcceptsValue<Result> {
	
	value listeners = HashMap<ListenerId, Anything(Result|Exception)>(withListeners);
	variable Result|Exception|NoValue result = noValue;
	value setterCount = AtomicInteger(0);
	value listenersSync = Sync();

	shared Integer attemptsToSet => setterCount.get();
	
	void setResultAndInformListeners(Result|Exception resultToSet) {
		this.result = resultToSet;
		for (listener in listeners.values) {
			listener(resultToSet);
		}
	}
	
	"Set the result of the computation. This method can be called only once,
	 an Exception is thrown otherwise."
	shared actual void set(Result|Exception resultToSet) {
		if (setterCount.getAndAdd(1) == 0) {
			listenersSync.syncExec(() => setResultAndInformListeners(resultToSet));
		} else {
			throw ForbiddenInvokationException("The value of this WritableOncePromise has already been set");
		}
	}
	
	shared actual Result|Exception|NoValue getOrNoValue() {
		return result;
	}
	
	void addOrJustInformListener(ListenerId id, Anything(Result|Exception) listener) {
		value currentResult = result;
		if (is NoValue currentResult) {
			listeners.put(id, listener);
		} else if (is Result|Exception currentResult) {
			listener(currentResult);
		}
	}
	
	shared actual ListenerId onCompletion(Anything(Result|Exception) listener) {
		value listenerId = ListenerIdImpl();
		listenersSync.syncExec(() => addOrJustInformListener(listenerId, listener));
		return listenerId;
	}
	
	shared actual Boolean stopListening(ListenerId listenerId) {
		return listenersSync.syncExec(() => listeners.remove(listenerId) exists);
	}
	
}
