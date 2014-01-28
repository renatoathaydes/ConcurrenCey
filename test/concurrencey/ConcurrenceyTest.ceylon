import ceylon.test {
	test, assertEquals
}

import concurrencey.internal {
	currentLane
}

import java.lang {
	Thread
}

shared class ConcurrenceyTest() extends TestWithLanes() {
	
	shared test void canRunActionInAnotherLane() {
		value lane = Lane("Lane");
		testingOn(lane);
		
		value actionResult = Action(() => currentLane()).runOn(lane);
		
		value result = actionResult.get();
		assert(is Lane result, result === lane);
	}
	
	shared test void canRunActionWithArgsInAnotherLane() {
		value lane = Lane("Lane B");
		testingOn(lane);
		
		String hi(String s) {
			return s;
		}
		
		value actionResult = Action(() => hi("Hi")).runOn(lane);
		
		value result = actionResult.get();
		assert(result == "Hi");
	}
	
	shared test void canRunActionsInParallel() {
		value sleepTime = 100;
		String slowString(String s) {
			Thread.sleep(sleepTime);
			return s;
		}
		value actions = ActionRunner(
			[Action(() => slowString("A")),
			Action(() => slowString("B")),
			Action(() => slowString("C")),
			Action(() => slowString("D")),
			Action(() => 1)]);
		
		value time_result = withTimer(() => actions.run());
		
		assert(2 * sleepTime > time_result.first);
		assert(exists resultPromises = actions.results());
		value results = [ for (item in resultPromises) if (is String|Integer obj = item.get()) obj ];
		assertEquals(results, ["A", "B", "C", "D", 1]);
	}
	
}
