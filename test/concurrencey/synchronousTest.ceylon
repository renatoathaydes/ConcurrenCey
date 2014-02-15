import ceylon.test {
	test,
	assertEquals,
	assertThatException
}
import ceylon.time {
	Duration,
	now,
	Period
}


class SynchronousValueTest() {
	
	value syncValue = SynchronousValue<String>();
	
	shared test void canProvideValueAfterSet() {
		syncValue.set("Hi");
		value result = syncValue.syncGet(Duration(100));
		assertEquals(result, "Hi");
	}
	
	shared test void canProvideValueWhenDelayedSetting() {
		Scheduler().schedule([now().plus(Period{ milliseconds=50; })], () => syncValue.set("Hi"));
		value result = syncValue.syncGet(Duration(1000));
		assertEquals(result, "Hi");
	}
	
	shared test void timeoutWhenNotSetInTime() {
		assertThatException(() => syncValue.syncGet(Duration(25))).hasType(`TimeoutException`);
	}
	
	shared test void canBeUsedByManyThreads() {
		value strings = [
		"Everything is fine",
		"Not all code is good",
		"I would not do this if I were you",
		"Concurrent code is easy to write",
		"What happens when many threads set a value",
		"Even if you use a lot of threads this will still work"];
		value results = StrategyActionRunner(UnlimitedLanesStrategy())
				.runActionsAndWait([
				Action(() => syncValue.set(strings[0])),
				Action(() => syncValue.set(strings[1])),
				Action(() => syncValue.set(strings[2])),
				Action(() => syncValue.set(strings[3])),
				Action(() => syncValue.set(strings[4])),
				Action(() => syncValue.set(strings[5]))
		]);
		assert(syncValue.syncGet(Duration(1000)) in strings);
		assertEquals(results.count((Anything s) => s is Exception), strings.size - 1);
	}
	
	shared test void throwsExceptionWhenExceptionIsSet() {
		syncValue.set(Exception("Bad"));
		assertThatException(() => syncValue.syncGet(Duration(100))).hasMessage("Bad");
	}
	
}
