import ceylon.test {
	test
}

import concurrencey {
	Lane,
	WritablePromise,
	TestWithLanes,
	sleep
}

import java.lang {
	Runnable,
	InterruptedException
}

shared class ThreadLaneTest() extends TestWithLanes() {
	
	shared test void canRunInLane() {
		Lane lane1 = Lane("Lane1");
		testingOn(lane1);
		value sleepTime = 150;
		object runnable satisfies Runnable {
			shared variable Boolean ran = false;
			shared actual void run() {
				sleep(sleepTime);
				ran = true;
			}
		}
		
		value startTime = system.milliseconds;
		runSoonest(lane1, runnable);
		value totalTime = system.milliseconds - startTime;
		
		sleep(sleepTime + 25);
		
		assert(runnable.ran);
		assert(totalTime < sleepTime);
	}
	
	shared test void canStopRunningLane() {
		Lane lane2 = Lane("Lane2");
		testingOn(lane2);
		value promise = WritablePromise<Boolean>();
		object runnable satisfies Runnable {
			shared actual void run() {
				promise.set(true);
			}
		}
		
		assert(isActive(lane2) == false);
		
		runSoonest(lane2, runnable);
		
		assert(promise.syncGet() == true);
		assert(isActive(lane2));
		
		value isStopped = stop(lane2);
		
		assert(isStopped);
		sleep(250);
		assert(!isActive(lane2));
	}
	
	shared test void canInterruptLane() {
		Lane lane3 = Lane("Lane3");
		testingOn(lane3);
		value timeStarted = WritablePromise<Integer>();
		value timeInterrupted = WritablePromise<Integer>();
		value timeToSleep = 250;
		object runnable satisfies Runnable {
			shared actual void run() {
				timeStarted.set(system.milliseconds);
				try {
					sleep(timeToSleep);
				} catch(InterruptedException e) {
					timeInterrupted.set(system.milliseconds);
				}
			}
		}
		
		runSoonest(lane3, runnable);
		value startTime = timeStarted.syncGet();
		assert(is Integer startTime);
		
		value confirmedStop = stop(lane3);
		
		assert(confirmedStop);
		
		value stopped = timeInterrupted.syncGet();
		assert(is Integer stopped);
		assert(stopped - startTime < timeToSleep);
	}
	
	shared test void laneCanBeRessurrected() {
		Lane lane4 = Lane("Lane4");
		testingOn(lane4);
		value promise1 = WritablePromise<Boolean>();
		value promise2 = WritablePromise<Boolean>();
		
		object runnable satisfies Runnable {
			shared actual void run() {
				promise1.set(true);
			}
		}
		
		object runnable2 satisfies Runnable {
			shared actual void run() {
				promise2.set(true);
			}
		}
		
		runSoonest(lane4, runnable);
		
		assert(promise1.syncGet() == true);
		
		stop(lane4);
		sleep(100);
		runSoonest(lane4, runnable2);
		
		assert(promise2.syncGet() == true);
	}
	
}

