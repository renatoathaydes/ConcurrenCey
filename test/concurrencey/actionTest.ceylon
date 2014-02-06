import ceylon.test {
	test,
	assertEquals
}

import concurrencey.internal {
	currentLane
}

class ActionTest() {
	
	value lane = Lane(`class ActionTest`.name);
	
	shared test void canRunActionInAnotherLane() {
		value promise = Action(() => currentLane()).runOn(lane);
		waitUntil(() => promise.getOrNoValue() is Lane, 2000);
		value result = promise.getOrNoValue();
		
		assert(is Lane result);
		assertEquals(result, lane);
	}
	
	shared test void canRunActionWithArgsInAnotherLane() {
		String hi(String s) {
			return s;
		}
		
		value promise = Action(() => hi("Hi")).runOn(lane);
		waitUntil(() => promise.getOrNoValue() is String, 2000);
		value result = promise.getOrNoValue();
		
		assert(result == "Hi");
	}
	
}
