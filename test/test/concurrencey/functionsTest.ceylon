import ceylon.test { test, assertThatException }
import com.athaydes.concurrencey {

    withTimer,
    sleep,
    waitUntil,
    TimeoutException
}

class FunctionsTest() {

	shared test void runWithTimerTest() {
		value result1 = withTimer(() => sleep(50));
		assert(50 <= result1.first);
		assert(result1.first < 80);
		value result2 = withTimer(() => "Hej");
		assert(result2[1] == "Hej");
		assert(0 <= result2.first, result2.first < 25); // 3-way comparison not working due to bug
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
		
}
