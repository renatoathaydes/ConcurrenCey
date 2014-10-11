import java.util.concurrent.atomic {
	AtomicLong
}


shared abstract class IdCreator() of idCreator {
	
	value idCounter = AtomicLong(-1P);
	
	shared Integer createId() {
		return idCounter.incrementAndGet();
	}
	
}

shared object idCreator extends IdCreator() {}

shared String generateLaneId(String name) => "``name``-``idCreator.createId()``";
