import ceylon.collection {
	HashMap
}

import concurrencey.internal {
	runSoonest,
	isLaneBusy
}

import java.lang {
	Runnable
}
import java.util.concurrent {
	CountDownLatch
}
import java.util.concurrent.atomic {
	AtomicInteger
}

"The result of a computation which has not completed successfully."
shared class ComputationFailed(
	shared Exception exception,
	shared String reason = "") {}

shared class TimeoutException(shared actual String message = "")
		extends Exception(message) {}

"A computation result destination"
shared interface AcceptsValue<in Result> {
	"Sets the result of a computation"
	shared formal void set(Result|ComputationFailed result);
}

"A computation result source"
shared interface HasValue<out Result> {
	"Returns the result of a computation, or [[ComputationFailed]] if the
	 computation has not completed yet or not completed successfully."
	shared formal Result|ComputationFailed syncGet();
	
	"Returns true if this [[HasValue]] can provide a result immediately, false otherwise.
	 
	 If this method returns true, calling [[HasValue.syncGet]] is guaranteed to return immediately.
	 If not, calling [[HasValue.syncGet]] will block until a value is available."
	shared formal Boolean hasValue();
}

"A key which can be used to identify listeners, for example to retrieve or remove them."
see(`interface AsyncHasValue`)
shared interface ListenerId {
	
}

class ListenerIdImpl(shared Integer key) satisfies ListenerId {}

"A computation result which can be accessed asynchronously."
shared interface AsyncHasValue<out Result> {
	
	"The given listener will be invoked on completion of the computation.
	 Many listeners can be added.
	 
	 Returns a [[ListenerId]] which can be used to stop listening."
	shared formal ListenerId onCompletion(Anything(Result|ComputationFailed) listener);
	
	"Make the given listener stop listening on the result of the computation.
	 
	 Returns true if and only if the listener was actually listening prior to this."
	shared formal Boolean stopListening(ListenerId listenerId);
	
}

"A Promise represents the future result of a computation which may or may not
 ever complete, and may complete successfully or fail."
shared alias Promise<out Result> => HasValue<Result>&AsyncHasValue<Result>; 

"A Writable version of [[Promise]]. Should only be used by the code actually running
 the computation. The Result of a computation should be set only once. Trying to set
 the Result more than once will result in an [[Exception]] being thrown."
shared class WritablePromise<Result>()
		satisfies HasValue<Result>&AsyncHasValue<Result>&AcceptsValue<Result> {
	
	value listeners = HashMap<ListenerId, Anything(Result|ComputationFailed)>();
	value listenerIdSource = AtomicInteger();
	value latch = CountDownLatch(1);
	late variable Result|ComputationFailed result;
	
	"Set the result of the computation. This method can be called only once,
	 an Exception is thrown otherwise."
	shared actual void set(Result|ComputationFailed result) {
		if (latch.count == 1) {
			this.result = result;
			latch.countDown();
			for (listener in listeners.values) {
				listener(result);
			}
		} else {
			throw Exception("The value of this WritablePromise has already been set");
		}
	}
	
	"Returns the result of an operation, blocking until the operation is
	 completed if necessary. To get the result asynchronously, use [[WritablePromise.onCompletion]]"
	shared actual Result|ComputationFailed syncGet() {
		latch.await();
		return result;
	}
	
	shared actual Boolean hasValue() {
		return latch.count < 1;
	}
	
	shared actual ListenerId onCompletion(Anything(Result|ComputationFailed) listener) {
		value listenerId = ListenerIdImpl(listenerIdSource.incrementAndGet());
		if (hasValue()) {
			listener(result);
		} else {
			listeners.put(listenerId, listener);
		}
		return listenerId;
	}
	
	shared actual Boolean stopListening(ListenerId listenerId) {
		return (listeners.remove(listenerId) exists);
	}
	
}

"A Lane represents a Thread where [[Action]]s may run. A Lane is not exactly the
 same as a Java Thread. A Lane might discard its current Thread if it has been long
 idle, for example, and start a new one only when necessary."
shared class Lane(shared String name) {
	
	shared Boolean busy => isLaneBusy(this);
	
	shared actual Boolean equals(Object other) {
		if (is Lane other, this.name == other.name) {
			return true;
		}
		return false;
	}
	
	shared actual Integer hash => name.hash;
	
}

"An entity which can be run on a [[Lane]]."
shared interface LaneRunnable<out Result> {
	"Runs this entity on a [[Lane]]."
	shared formal HasValue<Result> runOn(Lane lane);
}

"An Action represents a computation which can be run in one or more [[Lane]]s."
shared class Action<out Result>(Result() act)
		satisfies LaneRunnable<Result> {

	variable value writablePromise = WritablePromise<Result>();
	
	"The Promise currently associated with this action. This is updated at each run."
	shared Promise<Result> promise => writablePromise;
	
	void update(ComputationFailed|Result result) {
		writablePromise.set(result);
		writablePromise = WritablePromise<Result>();
	}
	
	"Run this action synchonously."
	shared default Result syncRun() {
		value result = act();
		update(result);
		return result;
	}
	
	shared default actual Promise<Result> runOn(Lane lane) {
		object runnable satisfies Runnable {
			shared actual void run() {
				try {
					update(act());
				} catch (e) {
					e.printStackTrace();
					update(ComputationFailed(e));
				}
			}
		}
		runSoonest(lane, runnable);
		return promise;
	}
	
}

"A special kind of [[Action]] which is guaranteed to only run once at most."
shared class OnceAction<out Result>(Result() act)
extends Action<Result>(act) {
	
	shared variable Boolean canRun = true;
	
	"Run this action synchonously."
	shared actual Result syncRun() {
		canRun = false;
		return super.syncRun();
	}
	
	shared actual Promise<Result> runOn(Lane lane) {
		canRun = false;
		return super.runOn(lane);
	}
	
}
