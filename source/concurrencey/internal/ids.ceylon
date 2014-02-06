import ceylon.language {
	shared,
	abstract
}

import java.util.concurrent.atomic {
	AtomicInteger
}


shared abstract class IdCreator() of idCreator {
	
	value idCounter = AtomicInteger(-1P);
	
	shared Integer createId() {
		return idCounter.incrementAndGet();
	}
	
}

shared object idCreator extends IdCreator() {}

shared String generateLaneId(String name) => "``name``-``idCreator.createId()``";
