import concurrencey.internal {
	internalCurrentLane=currentLane
}

import java.lang {
	Thread
}

"Causes the currently executing thread to sleep (temporarily cease execution)
 for the specified number of milliseconds, subject to the precision and accuracy
 of system timers and schedulers.
 
 See Java's java.lang.Thread#sleep for details."
shared void sleep(Integer timeInMillis) {
	Thread.sleep(timeInMillis);
}

"Runs the provided act, recording the time it took for it to return.
 
 Returns a tuple containing the recorded time in milliseconds and the
 object returned by act."
shared [Integer, Result] withTimer<Result>(Result()|Action<Result> act) {
	variable Integer startTime;
	variable Integer endTime;
	variable Result result;
	if (is Result() act) {
		startTime = system.milliseconds;
		result = act();
		endTime = system.milliseconds;
	} else {
		assert(is Action<Result> act);
		startTime = system.milliseconds;
		result = act.syncRun();
		endTime = system.milliseconds;
	}
	return [endTime - startTime, result];
}

"Waits until the given condition is true, within a timeout."
throws(`class TimeoutException`, "when the timeout is reached.")
shared void waitUntil(
	Boolean() condition,
	Integer timeoutInMillis = 30_000,
	Integer pollingTime = 10) {
	
	Integer timeoutTime = system.milliseconds + timeoutInMillis;
	value conditionPromise = Action(condition).runOn(Lane("waitUntil-lane"));
	while (true) {
		if (conditionPromise.hasValue()) {
			value result = conditionPromise.syncGet();
			if (is ComputationFailed result) {
				throw result.exception;
			} else if (result == true) {
				return;
			}
		}
		if (system.milliseconds > timeoutTime) {
			throw TimeoutException("Condition was not met within ``timeoutInMillis`` ms");
		}
		sleep(pollingTime);
	}
}

"Returns the [[Lane]] where the caller is running from.
 
 May return null if the caller is not running on an existing Lane."
shared Lane? currentLane() {
	return internalCurrentLane();
}
