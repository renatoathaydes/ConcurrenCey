import ceylon.collection {
	HashMap
}
import ceylon.language {
	shared
}

import concurrencey.internal {
	runSoonest,
	idCreator
}


import java.lang {
	Runnable
}
import java.util.concurrent.atomic { AtomicInteger }

"The result of a computation which has not completed successfully."
shared class ComputationFailed(
	shared Exception exception,
	shared String reason = "") {}

shared class ComputationFailedWithId(
	shared Integer id,
	Exception exception,
	String reason = "") extends ComputationFailed(exception, reason) {}

shared class TimeoutException(shared actual String message = "")
		extends Exception(message) {}

"A computation result destination"
shared interface AcceptsValue<in Result, in Failure=ComputationFailed>
		given Failure satisfies Object {
	"Sets the result of a computation"
	shared formal void set(Result|Failure result);
}

"Indicates that a value has not been set yet for a [[HasValue]]."
shared abstract class NoValue() of noValue {}

shared object noValue extends NoValue() {}

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
		if (is Result|ComputationFailed currentResult) {
			listener(currentResult);
		}
		return listenerId;
	}
	
	shared actual Boolean stopListening(ListenerId listenerId) {
		return (listeners.remove(listenerId) exists);
	}
	
}

"An Action represents a computation which can be run a single time,
 synchronously or asynchronously (in a different [[Lane]].
 
 If running an Action asynchronously, the result of the computation
 is provided by a [[Promise]]."
shared abstract class ActionBase<out Result, out Failure=ComputationFailed>(
	Result() act)
		given Failure satisfies Object {
	
	value writablePromise = WritableOncePromise<Result, Failure>();
	
	"The Promise associated with this action."
	shared default Promise<Result, Failure> promise = writablePromise;
	
	void update(Failure|Result result) {
		writablePromise.set(result);
	}
	
	void assertCanRun() {
		if (!writablePromise.getOrNoValue() is NoValue) {
			throw Exception("Action can run only once!");
		}
	}
	
	"Adaptor to transform the source of a Failure into the actual Failure type"
	shared formal Failure failureAdaptor(Exception exception);
	
	"Run this action synchonously."
	shared default Result syncRun() {
		assertCanRun();
		value result = act();
		update(result);
		return result;
	}
	
	"Run this action on a specific [[Lane]]. **This method is intended to be called
	 by the Concurrencey framework only.**"	
	shared default Promise<Result, Failure> runOn(Lane lane) {
		assertCanRun();
		object runnable satisfies Runnable {
			shared actual void run() {
				try {
					update(act());
				} catch (e) {
					e.printStackTrace();
					update(failureAdaptor(e));
				}
			}
		}
		runSoonest(lane, runnable);
		return promise;
	}
	
}

"An Action represents a computation which can be run a single time,
 synchronously or asynchronously (in a different [[Lane]].
 
 If running an Action asynchronously, the result of the computation
 is provided by a [[Promise]]."
shared class Action<out Result>(Result() act)
		extends ActionBase<Result, ComputationFailed>(act) {
	
	failureAdaptor(Exception e) => ComputationFailed(e); 
	
}

"An [[Action]] which has an ID, useful to map several results to their corresponding Actions"
shared class IdAction<Id, Result>(
	shared Id id,
	[Id, Result]() act)
		extends ActionBase<[Id, Result], [Id, ComputationFailed]>(act)
		given Id satisfies Object {
	
	shared actual [Id, ComputationFailed] failureAdaptor(Exception exception) =>
			[id, ComputationFailed(exception)];
	
}
