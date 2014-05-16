import ceylon.collection {
    HashSet,
    unlinked,
    Hashtable
}
import ceylon.test {
    assertEquals,
    test
}

import java.util {
    Random
}

class LaneIdProviderTest() {

	shared test void generatedIdsAreUnique() {
		value random = Random();
		value randomIds = (1..1000)
				.map((Anything _) => random.nextInt(10).string)
				.collect(generateLaneId);
		assertEquals(HashSet(unlinked, Hashtable{ initialCapacity = 1000; },
			randomIds).size, randomIds.size);
	}

}
