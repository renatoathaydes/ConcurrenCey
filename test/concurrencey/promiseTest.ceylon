import ceylon.test {
	assertEquals,
	test,
	assertThatException
}


class WritableOncePromiseTest() {
	
	value promise = WritableOncePromise<String>();
	
	shared test void canProvideResultImmediately() {
		promise.set("Hi");
		assertEquals(promise.getOrNoValue(), "Hi");
	}
	
	shared test void canProvideResultManyTimesAfterSet() {
		promise.set("Hi");
		assertEquals(promise.getOrNoValue(), "Hi");
		assertEquals(promise.getOrNoValue(), "Hi");
		assertEquals(promise.getOrNoValue(), "Hi");
	}
	
	shared test void canProvideResultAsyncWhenValueIsSetEarlier() {
		promise.set("Hi");
		variable Anything capture = null;
		promise.onCompletion((String|ComputationFailed s) => capture = s);
		assert(exists result = capture);
		assertEquals("Hi", result);
	}
	
	shared test void canProvideResultAsyncWhenValueIsSetLater() {
		variable Anything capture = null;
		function doCapture(String|ComputationFailed s) {
			capture = s;
			return s;
		}
		promise.onCompletion(doCapture);
		
		promise.set("Hi");
		
		assert(exists result = capture);
		assertEquals(result, "Hi");
	}
	
	shared test void moreThanOneListenerCanBeAdded() {
		variable Anything capture1 = null;
		variable Anything capture2 = null;
		variable Anything capture3 = null;
		promise.onCompletion((String|ComputationFailed s) => capture1 = s);
		promise.onCompletion((String|ComputationFailed s) => capture2 = s);
		promise.onCompletion((String|ComputationFailed s) => capture3 = s);
		
		promise.set("Hi");
		
		for (capture in [capture1, capture2, capture3]) {
			assert(exists result = capture);
			assertEquals(result, "Hi");	
		}
	}
	
	shared test void listenerCanBeRemoved() {
		variable Anything capture1 = null;
		variable Anything capture2 = null;
		
		value id = promise.onCompletion((String|ComputationFailed s) => capture1 = s);
		promise.onCompletion((String|ComputationFailed s) => capture2 = s);
		value ok = promise.stopListening(id);
		promise.set("Hi");
		
		assert(ok);
		assert(capture1 is Null);
		assert(exists c = capture2);
		assertEquals(c, "Hi");
	}
	
	shared test void cannotBeSetMoreThanOnce() {
		promise.set("Hi");
		assertThatException(() => promise.set("Hej")).hasType(`Exception`);
	}
	
}
