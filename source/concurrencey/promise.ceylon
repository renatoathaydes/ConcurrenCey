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
shared interface AcceptsValue<in Result, in Failure=ComputationFailed>
		given Failure satisfies Object {
	"Sets the result of a computation"
	shared formal void set(Result|Failure result);
}


"A computation result source"
shared interface HasValue<out Result, out Failure=ComputationFailed>
		given Failure satisfies Object {
	
	"Returns the result of a computation if this [[HasValue]] can provide it
	 immediately, or a [[NoValue]] otherwise."
	shared formal Result|Failure|NoValue getOrNoValue();
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
shared interface AsyncHasValue<out Result, out Failure=ComputationFailed>
		given Failure satisfies Object {
	
	"The given listener will be invoked on completion of the computation.
	 Many listeners can be added.
	 
	 Returns a [[ListenerId]] which can be used to stop listening."
	see(`function stopListening`)
	shared formal ListenerId onCompletion(Anything(Result|Failure) listener);
	
	"Unregister the listener with the given ID.
	 
	 Returns true if and only if the listener was actually listening prior to this."
	shared formal Boolean stopListening(ListenerId listenerId);
	
}

"A Promise represents the future result of a computation which may or may not
 ever complete, and may complete successfully or fail."
shared interface Promise<out Result, out Failure=ComputationFailed>
		satisfies HasValue<Result, Failure>&AsyncHasValue<Result, Failure>
		given Failure satisfies Object {} 

"A Writable version of [[Promise]]. The Result of a computation should be set only once.
 Trying to set the Result more than once will result in an [[Exception]] being thrown."
shared class WritableOncePromise<Result, Failure=ComputationFailed>(
	{<ListenerId->Anything(Result|Failure)>*} withListeners = {})
		satisfies Promise<Result, Failure>&AcceptsValue<Result, Failure>
		given Failure satisfies Object {
	
	value listeners = HashMap<ListenerId, Anything(Result|Failure)>(withListeners);
	variable Result|Failure|NoValue result = noValue;
	value setterCount = AtomicInteger(0);
	
	"Set the result of the computation. This method can be called only once,
	 an Exception is thrown otherwise."
	shared actual void set(Result|Failure resultToSet) {
		if (setterCount.getAndAdd(1) == 0) {
			this.result = resultToSet;
			for (listener in listeners.values) {
				listener(resultToSet);
			}
		} else {
			throw Exception("The value of this WritablePromise has already been set");
		}
	}
	
	shared actual Result|Failure|NoValue getOrNoValue() {
		return result;
	}
	
	shared actual ListenerId onCompletion(Anything(Result|Failure) listener) {
		value listenerId = ListenerIdImpl();
		value currentResult = result;
		if (is NoValue currentResult) {
			listeners.put(listenerId, listener);
		}
		if (is Result|Failure currentResult) {
			listener(currentResult);
		}
		return listenerId;
	}
	
	shared actual Boolean stopListening(ListenerId listenerId) {
		return (listeners.remove(listenerId) exists);
	}
	
}
