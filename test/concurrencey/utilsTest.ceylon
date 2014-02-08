import ceylon.collection {
	LinkedList
}
import ceylon.test {
	test,
	assertEquals
}

class SyncTest() {
	
	shared test void canSafelyShareResourceInsideSyncedFunction() {
		
		value resourceSync = Sync();
		value resource = LinkedList<Integer>();
		value startTime = system.milliseconds;
		
		void useResource() {
			resource.add(system.milliseconds);
		}
		
		value runner = StrategyActionRunner(UnlimitedLanesStrategy());
		
		runner.runActionsAndWait((1..1000).collect((Anything _) => Action(() => resourceSync.syncExec(useResource))));
		
		value endTime = system.milliseconds;
		
		assertEquals(resource.size, 1000);
		assert(resource.every((Integer t) => startTime < t < endTime));
	}
	
}