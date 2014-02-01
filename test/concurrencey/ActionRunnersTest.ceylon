import ceylon.test {
	assertEquals,
	test
}
import java.util { Random }
import ceylon.collection { HashSet }

shared class ActionRunnerTest() {
	
	value sleepTime = 100;
	
	String slowString(String s) {
		sleep(sleepTime);
		return s;
	}
	
	shared test void canRunActionsUsingUnlimitedLanesStrategy() {
		value runner = StrategyActionRunner(UnlimitedLanesStrategy());
		
		function runAll() {
			value promises = runner.runActions([
			Action(() => slowString("A")),
			Action(() => slowString("B")),
			Action(() => slowString("C")),
			Action(() => slowString("D")),
			Action(() => 1)]);
			return [for (p in promises) p.syncGet()];
		}
		
		value time_result = withTimer(runAll);
		
		assert(sleepTime <= time_result.first < 2 * sleepTime);
		value results = time_result[1];
		assertEquals(results, ["A", "B", "C", "D", 1]);
	}
	
	shared test void canRunActionsSynchronouslyUsingSingleLaneStrategy() {
		value runner = StrategyActionRunner(SingleLaneStrategy());
		
		function runAll() {
			value promises = runner.runActions([
			Action(() => slowString("A")),
			Action(() => slowString("B")),
			Action(() => slowString("C"))]);
			return [for (p in promises) p.syncGet()];
		}
		
		value time_result = withTimer(runAll);
		
		assert(3 * sleepTime <= time_result.first < 4 * sleepTime);
		value results = time_result[1];
		assertEquals(results, ["A", "B", "C"]);
	}
	
	shared test void canRunActionsUsingLimitedLaneStrategy() {
		value runner = StrategyActionRunner(LimitedLanesStrategy(2));
		
		function runAll() {
			value promises = runner.runActions([
			Action(() => slowString("A")),
			Action(() => slowString("B")),
			Action(() => slowString("C")),
			Action(() => slowString("D"))]);
			return [for (p in promises) p.syncGet()];
		}
		
		value time_result = withTimer(runAll);
		print("Time was ``time_result.first``");
		
		assert(2 * sleepTime <= time_result.first < 3 * sleepTime);
		value results = time_result[1];
		assertEquals(results, ["A", "B", "C", "D"]);
	}
	
}

shared class LaneIdProviderTest() {
	
	shared test void generatesExpectedIds() {
		assertEquals(laneIdGenerator.generateId("abc")[0..3], "abc-");
		assertEquals(laneIdGenerator.generateId("lane", 1)[0..6], "lane-1-");
		assertEquals(laneIdGenerator.generateId("lane", 2, 3)[0..8], "lane-2-3-");
	}
	
	shared test void generatedIdsAreUnique() {
		value random = Random();
		value randomIds = (1..1000)
				.map((Anything _) => random.nextInt(10))
				.map(laneIdGenerator.generateId);
		assertEquals(HashSet(randomIds).size, randomIds.size);
	}
	
}
