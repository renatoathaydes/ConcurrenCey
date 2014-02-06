import ceylon.test {
	test
}

import concurrencey.internal {
	assertElementsEqual
}

class ActionRunnerTest() {
	
	value sleepTime = 100;
	
	String slowString(String s) {
		print("Slow string with ``s``");
		sleep(sleepTime);
		return s;
	}

	shared test void canRunActionsSynchronouslyUsingSingleLaneStrategy() {
		value runner = StrategyActionRunner(SingleLaneStrategy());
		
		function runAll() {
			value results = runner.runActionsAndWait([
			Action(() => slowString("A")),
			Action(() => slowString("B")),
			Action(() => slowString("C"))]);
			return results;
		}
		
		value time_result = withTimer(runAll);
		
		assert(3 * sleepTime <= time_result.first < 4 * sleepTime);
		value results = time_result[1];
		assertElementsEqual(results, { "A", "B", "C" });
	}
	
	shared test void singleLaneStrategyEnsuresActionsRunSynchronously() {
		value runner = StrategyActionRunner(SingleLaneStrategy());
		value times = Array({0, 0, 0, 0, 0});
		
		runner.runActionsAndWait([
		Action(() => times.set(0, system.milliseconds)),
		Action(() => times.set(1, system.milliseconds)),
		Action(() => times.set(2, system.milliseconds)),
		Action(() => times.set(3, system.milliseconds)),
		Action(() => times.set(4, system.milliseconds))
		]);
		assertElementsEqual(times, times.sort(byIncreasing((Integer t) => t)));
	}
	
	shared test void canRunActionsUsingUnlimitedLanesStrategy() {
		value runner = StrategyActionRunner(UnlimitedLanesStrategy());
		
		function runAll() {
			value results = runner.runActionsAndWait([
			Action(() => slowString("A")),
			Action(() => slowString("B")),
			Action(() => slowString("C")),
			Action(() => slowString("D")),
			Action(() => 1), Action(() => 2), Action(() => 3)]);
			return results;
		}
		
		value time_result = withTimer(runAll);
		
		assert(sleepTime <= time_result.first < 2 * sleepTime);
		value results = time_result[1];
		assertElementsEqual(results, { "A", "B", "C", "D", 1, 2, 3 });
	}
	
	shared test void canRunActionsUsingLimitedLaneStrategy() {
		value runner = StrategyActionRunner(LimitedLanesStrategy(2));
		
		function runAll() {
			value results = runner.runActionsAndWait([
			Action(() => slowString("A")),
			Action(() => slowString("B")),
			Action(() => slowString("C")),
			Action(() => slowString("D"))]);
			return results;
		}
		
		value time_result = withTimer(runAll);
		print("Time was ``time_result.first``");
		
		assert(2 * sleepTime <= time_result.first < 3 * sleepTime);
		value results = time_result[1];
		assertElementsEqual(results, { "A", "B", "C", "D" });
	}
	
}
