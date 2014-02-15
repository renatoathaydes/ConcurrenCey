import ceylon.test { test, assertThatException }

class FunctionsTest() {

	shared test void runWithTimerTest() {
		value result1 = withTimer(() => sleep(50));
		assert(50 <= result1.first < 80);
		value result2 = withTimer(() => "Hej");
		assert(result2[1] == "Hej");
		assert(0 <= result2.first < 25);
	}
	
	shared test void testWaitUntilWithSuccess() {
		value result = withTimer(() => waitUntil(() => true));
		assert(result.first < 15);
	}

	shared test void testWaitUntilWithTimeout() {
		Boolean slowAct() {
			sleep(50);
			return true;
		}
		assertThatException(() => waitUntil(slowAct, 5))
				.hasType(`TimeoutException`);
	}
	
	shared test void testWaitUntilWithImpossibleCondition() {
		assertThatException(() => waitUntil(() => false, 25, 5))
				.hasType(`TimeoutException`);
	}
	
	shared test void testEquivalent() {
		assert(equivalent(1, 1));
		assert(equivalent(null, null));
		assert(equivalent("Hi", "Hi"));
		assert(equivalent({1, 2, 3}, {1, 2, 3}));
		assert(equivalent({1, 2, null, 3}, {1, 2, null, 3}));
		assert(equivalent({null}, {null}));
		assert(equivalent(Array({1,2}), Array({1,2})));
		assert(equivalent(Array({null,null}), Array({null,null})));
		assert(equivalent({{null}, {null}}, {{null},{null}}));
		
		assert(!equivalent(1, 2));
		assert(!equivalent(null, 1));
		assert(!equivalent(1, null));
		assert(!equivalent("Hi", "Ho"));
		assert(!equivalent({1, 2}, {1, 2, 3}));
		assert(!equivalent({1, 2, null, 3}, {1, 2, 3, null}));
		assert(!equivalent({null}, {}));
		assert(!equivalent({null}, {"null"}));
		assert(!equivalent({{null}, {null}}, {{null}}));
		assert(!equivalent(Array({1,2}), Array({1,2, 3})));
		assert(!equivalent(Array({null,null}), Array({null})));
	}
	
}
