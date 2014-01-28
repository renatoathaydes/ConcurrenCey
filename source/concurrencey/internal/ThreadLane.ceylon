import concurrencey {
	Lane
}

import java.lang {
	Runnable,
	Thread,
	InterruptedException
}
import java.util {
	Collections,
	ArrayList,
	JList=List,
	JMap=Map,
	HashMap
}
import java.util.concurrent {
	LinkedBlockingDeque,
	TimeUnit
}

JMap<String, OnDemandThread|Null> threads = Collections.synchronizedMap(HashMap<String, OnDemandThread|Null>());

JList<Lane> busyLanes = Collections.synchronizedList(ArrayList<Lane>());

variable {<Anything(Lane)->{Lane*}>*} freeLaneListeners = {};

shared Boolean isLaneBusy(Lane lane) {
	return busyLanes.contains(lane);
}

shared void listenForFreeLane(Anything(Lane) listener, {Lane*} fromLanes) {
	freeLaneListeners = freeLaneListeners.chain({ listener -> fromLanes });
}

void notifyLaneListeners(Lane lane) {
	value laneListeners = freeLaneListeners
			.filter((Anything(Lane)->{Lane*} entry) =>
			lane in entry.item);
	for (listener in laneListeners) {
		value notifyFree = listener.key;
		notifyFree(lane);
	}
	freeLaneListeners = freeLaneListeners
			.filter((Anything(Lane)->{Lane*} item) => item in laneListeners);
}

class OnDemandThread(shared Lane lane) {
	
	value queue = LinkedBlockingDeque<Runnable?>();
	variable Boolean die = false;
	variable Boolean running = false;
	
	void loop() {
		print("Started loop of Thread ``Thread.currentThread().name``");
		while(true, !die) {
			try {
				value action = queue.poll(1M, TimeUnit.\iDAYS);
				if (exists action) {
					busyLanes.add(lane);
					action.run();
				}
			} catch (InterruptedException e) {
				print("Thread ``lane.name`` interrupted");
			} finally {
				if (queue.empty) {
					busyLanes.remove(lane);
					notifyLaneListeners(lane);
				}
			}
		}
		threads.remove(lane.name);
		running = false;
		print("Thread ``lane.name`` dying");
	}
	
	object looper satisfies Runnable {
		shared actual void run() {
			running = true;
			loop();
		}
	}
	
	shared Thread thread = Thread(looper, lane.name);
	thread.daemon = true;
	
	shared void runNext(Runnable toRun) {
		die = false;
		if (!running) {
			thread.start();
		}
		queue.add(toRun);
	}
	
	shared Boolean isRunning() {
		return running;
	}
	
	shared void done() {
		die = true;
		thread.interrupt();
	}
	
}

shared void runSoonest(Lane lane, Runnable runnable) {
	initIfNecessary(lane).runNext(runnable);
}

shared Boolean stop(Lane lane) {
	if (exists thread = threads.get(lane.name)) {
		thread.done();
		return true;
	}
	return false;
}

shared Boolean isActive(Lane lane) {
	if (exists thread = threads.get(lane.name)) {
		return thread.isRunning();
	}
	return false;
}

shared Lane|[] currentLane() {
	Thread currentThread = Thread.currentThread();
	value onDemandThread = threads.get(currentThread.name);
	if (exists onDemandThread, onDemandThread.thread === currentThread) {
		return onDemandThread.lane;
	} else {
		return empty;
	}
}

OnDemandThread initIfNecessary(Lane lane) {
	OnDemandThread thread = threads.get(lane.name) else OnDemandThread(lane);
	threads.put(lane.name, thread);
	return thread;
}

