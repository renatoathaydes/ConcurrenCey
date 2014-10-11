import concurrencey.internal {
	runSoonest
}

import java.lang {
	Runnable
}
import java.util.concurrent.atomic { AtomicBoolean }


"An Action represents a computation which can be run a single time,
 synchronously (blocking) or asynchronously (in a different [[Lane]]).
 
 If running an Action asynchronously, the result of the computation
 is provided by a [[Promise]]."
shared class Action<out Result>(Result() act) {
	
	value hasRun = AtomicBoolean(false);
	value writablePromise = WritableOncePromise<Result>();
	
	"The Promise associated with this action."
	shared default Promise<Result> promise = writablePromise;
	
	void update(Result|Exception result) {
		writablePromise.set(result);
	}
	
	void assertCanRun() {
		if (hasRun.getAndSet(true)) {
			throw ForbiddenInvokationException("Action can run only once!");
		}
	}
	
	"Run this action synchonously."
	shared default Result syncRun() {
		assertCanRun();
		value result = act();
		update(result);
		return result;
	}
	
	"Run this action on a specific [[Lane]]"	
	shared default Promise<Result> runOn(Lane lane) {
		assertCanRun();
		object runnable satisfies Runnable {
			shared actual void run() {
				try {
					update(act());
				} catch (e) {
					update(e);
				}
			}
		}
		runSoonest(lane, runnable);
		return writablePromise;
	}
	
}

"An [[Action]] which has an ID, useful to map several results to their corresponding Actions"
shared class IdAction<Result>(
	shared Integer id,
	[Integer, Result]() act)
		extends Action<[Integer, Result]>(act) {}
