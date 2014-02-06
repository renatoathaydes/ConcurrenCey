import ceylon.language {
	shared
}

import concurrencey.internal {
	runSoonest
}

import java.lang {
	Runnable
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
