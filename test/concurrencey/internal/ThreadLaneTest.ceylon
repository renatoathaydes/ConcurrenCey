import ceylon.test {
	test
}

import concurrencey {
	Lane,
	WritablePromise,
	TestWithLanes
}

import java.lang {
	Runnable,
	Thread,
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
				Thread.sleep(sleepTime);
				ran = true;
			}
		}
		
		value startTime = system.milliseconds;
		runSoonest(lane1, runnable);
		value totalTime = system.milliseconds - startTime;
		
		Thread.sleep(sleepTime + 25);
		
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
		
		assert(promise.get() == true);
		assert(isActive(lane2));
		
		value isStopped = stop(lane2);
		
		assert(isStopped);
		Thread.sleep(250);
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
					Thread.sleep(timeToSleep);
				} catch(InterruptedException e) {
					timeInterrupted.set(system.milliseconds);
				}
			}
		}
		
		runSoonest(lane3, runnable);
		value startTime = timeStarted.get();
		assert(is Integer startTime);
		
		stop(lane3);
		
		value stopped = timeInterrupted.get();
		assert(is Integer stopped);
		assert(stopped - startTime < timeToSleep);
	}
	
	shared test void laneCanBeRessurrected() {
		Lane lane4 = Lane("Lane4");
		testingOn(lane4);
		value runs = WritablePromise<Boolean>();
		object runnable satisfies Runnable {
			shared actual void run() {
				runs.set(true);
			}
		}
		
		runSoonest(lane4, runnable);
		
		assert(runs.get() == true);
		
		stop(lane4);
		Thread.sleep(100);
		runSoonest(lane4, runnable);
		
		assert(runs.get() == true);
	}
	
}

