import ceylon.collection {
	HashSet
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
				.map(generateLaneId);
		assertEquals(HashSet(randomIds).size, randomIds.size);
	}
	
}

shared void assertElementsEqual({Object*} iterable1, {Object*} iterable2) {
	if (iterable1.sequence != iterable2.sequence) {
		throw AssertionException("``iterable1`` != ``iterable2``");
	}
}
