import ceylon.test {
	test
}

import concurrencey {
	WritableOncePromise,
	sleep,
	waitUntil, Lane
}


import java.lang {
	Runnable,
	InterruptedException
}

class ThreadLaneTest() {
	
	shared test void canRunInLane() {
		value lane1 = Lane("Lane1");
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
		value promise = WritableOncePromise<Boolean>();
		object runnable satisfies Runnable {
			shared actual void run() {
				promise.set(true);
			}
		}
		
		assert(isActive(lane2) == false);
		
		runSoonest(lane2, runnable);
		
		waitUntil(() => promise.getOrNoValue() == true, 2000);
		assert(isActive(lane2));
		
		value isStopped = stop(lane2);
		
		assert(isStopped);
		sleep(250);
		assert(!isActive(lane2));
	}
	
	shared test void canInterruptLane() {
		Lane lane3 = Lane("Lane3");
		value timeStarted = WritableOncePromise<Integer>();
		value timeInterrupted = WritableOncePromise<Integer>();
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
		waitUntil(() => timeStarted.getOrNoValue() is Integer, 2000);
		value startTime = timeStarted.getOrNoValue();
		assert(is Integer startTime);
		
		value confirmedStop = stop(lane3);
		
		assert(confirmedStop);
		
		waitUntil(() => timeInterrupted.getOrNoValue() is Integer, 2000);
		value stopped = timeInterrupted.getOrNoValue();
		assert(is Integer stopped);
		assert(stopped - startTime < timeToSleep);
	}
	
	shared test void laneCanBeRessurrected() {
		Lane lane4 = Lane("Lane4");
		value promise1 = WritableOncePromise<Boolean>();
		value promise2 = WritableOncePromise<Boolean>();
		
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
		
		waitUntil(() => promise1.getOrNoValue() == true, 2000);
		
		stop(lane4);
		sleep(100);
		runSoonest(lane4, runnable2);
		
		waitUntil(() => promise2.getOrNoValue() == true, 2000);
	}
	
}

