import ceylon.test {
	test, beforeTest, assertThatException,
    assertTrue
}
import ceylon.time {
	now,
	Instant
}
import com.athaydes.concurrencey {

    Scheduler,
    Lane,
    Action,
    waitUntil,
    NoValue,
    Promise,
    sleep
}


class SchedulerTest() {
	
	value scheduler = Scheduler();
	value testLane = Lane("test-lane");
	
	shared beforeTest void setup() {
		scheduler.schedule([now()], () => "start up Lane");
		
	}
	
	shared test void canScheduleActionToRunInAnInstant() {
		value checkTime = Action(() => system.milliseconds);
		value inAMoment = Instant(system.milliseconds + 50);
		value startTime = system.milliseconds;
		
		scheduler.schedule([inAMoment], () => checkTime.runOn(testLane));
		
		waitUntil(() => !checkTime.promise.getOrNoValue() is NoValue, 2000);
		value actualTime = checkTime.promise.getOrNoValue();
		assert(is Integer actualTime);
		assert(startTime + 50 <= actualTime < startTime + 75);
	}
	
	shared test void canScheduleActionToRunAtFixedRate() {
		function time() => system.milliseconds;
		value actions = [ Action(time), Action(time), Action(time) ];
		
		
		value iter = actions.iterator();
		void runNextAction() {
			if (is Action<Integer> action = iter.next()) {
				action.runOn(testLane);
			}
		}
		
		value inAMoment = Instant(system.milliseconds + 50);
		value startTime = system.milliseconds;
		
		scheduler.scheduleAtFixedRate(inAMoment, 25, runNextAction);
		
		waitUntil(() => actions*.promise.every((Promise<Integer> p) => !p.getOrNoValue() is NoValue), 2000);
		
		scheduler.shutDown();
		
		value expectedDelays = [ 50, 75, 100 ].iterator();
		
		for (promise in actions*.promise) {
			value actualTime = promise.getOrNoValue();
			value expectedDelay = expectedDelays.next();
			assert(is Integer actualTime, is Integer expectedDelay);
			assertTrue(startTime + expectedDelay <= actualTime < startTime + expectedDelay + 25,
			 "Actual time outside of acceptable bounds: ``actualTime``");
		}
		
	}
	
	shared test void canCancelTaskBeforeRunning() {
		value checkTime = Action(() => system.milliseconds);
		value inAMoment = Instant(system.milliseconds + 50);
		
		value task = scheduler.schedule([inAMoment], () => checkTime.runOn(testLane));
		
		task.cancel();
		sleep(100);
		
		assert(checkTime.promise.getOrNoValue() is NoValue);
	}
	
	shared test void canCancelRepeatingTaskBeforeRunning() {
		value checkTime = Action(() => system.milliseconds);
		value inAMoment = Instant(system.milliseconds + 50);
		
		value task = scheduler.scheduleAtFixedRate(inAMoment, 25, () =>
				checkTime.runOn(testLane));
		
		task.cancel();
		sleep(100);
		
		assert(checkTime.promise.getOrNoValue() is NoValue);
	}
	
	shared test void exceptionIsThrownIfSchedulingTaskOnShutDownScheduler() {
		scheduler.shutDown();
		assertThatException(() => scheduler.schedule([now()], void () {}));//.hasType(`ForbiddenInvokationException`);
	}
	
}