import ceylon.test {
	assertEquals,
	test
}

shared class ActionRunnerTest() {
	
	value sleepTime = 100;
	
	String slowString(String s) {
		sleep(sleepTime);
		return s;
	}
	
	shared test void canRunActionsUsingUnlimitedLanesStrategy() {
		value runner = StrategyActionRunner();
		
		value promises = runner.runActions([
		Action(() => slowString("A")),
		Action(() => slowString("B")),
		Action(() => slowString("C")),
		Action(() => slowString("D")),
		Action(() => 1)]);
		
		value time_result = withTimer(() => [for (p in promises) p.syncGet()]);
		
		assert(sleepTime <= time_result.first < 2 * sleepTime);
		value results = time_result[1];
		assertEquals(results, ["A", "B", "C", "D", 1]);
	}
	
	shared test void canRunActionsSynchronouslyUsingSingleLaneStrategy() {
		value runner = StrategyActionRunner(singleLaneStrategy);
		
		value promises = runner.runActions([
		Action(() => slowString("A")),
		Action(() => slowString("B")),
		Action(() => slowString("C"))]);
		
		value time_result = withTimer(() => [for (p in promises) p.syncGet()]);
		
		assert(3 * sleepTime <= time_result.first < 4 * sleepTime);
		value results = time_result[1];
		assertEquals(results, ["A", "B", "C"]);
	}
	
	shared test void canRunActionsUsingLimitedLaneStrategy() {
		value runner = StrategyActionRunner(LimitedLanesStrategy(2));
		
		value promises = runner.runActions([
		Action(() => slowString("A")),
		Action(() => slowString("B")),
		Action(() => slowString("C")),
		Action(() => slowString("D"))]);
		
		value time_result = withTimer(() => [for (p in promises) p.syncGet()]);
		
		assert(2 * sleepTime <= time_result.first < 4 * sleepTime);
		value results = time_result[1];
		assertEquals(results, ["A", "B", "C", "D"]);
	}
	
}
