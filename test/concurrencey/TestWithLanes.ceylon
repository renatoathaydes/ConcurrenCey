import ceylon.test { afterTest }
import concurrencey.internal { isActive, stop }
shared class TestWithLanes() {
	variable {Lane*} testLanes = [];
	
	shared afterTest void cleanUp() {
		for (lane in testLanes) {
			if (isActive(lane)) {
				try {
					stop(lane);
				} catch(e) {}
			}	
		}
	}
	
	shared void testingOn(Lane lane) {
		testLanes = testLanes.chain({lane});
	}
	
}