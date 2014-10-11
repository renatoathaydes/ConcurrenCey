import ceylon.collection {
	HashMap,
	MutableList
}

import concurrencey {
	Lane,
	Sync
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
	JHMap=HashMap
}
import java.util.concurrent {
	LinkedBlockingDeque,
	TimeUnit
}
import java.util.concurrent.atomic {
	AtomicBoolean
}

alias LaneWaiters => HashMap<Lane, [Sync, MutableList<Lane>]>;

JMap<String, OnDemandThread> threads = Collections.synchronizedMap(JHMap<String, OnDemandThread>());

JList<Lane> busyLanes = Collections.synchronizedList(ArrayList<Lane>());

LaneWaiters freeLaneWaiters = HashMap<Lane, [Sync, MutableList<Lane>]>();

shared Boolean isLaneBusy(Lane lane) {
	return busyLanes.contains(lane);
}

shared void returnLaneWhenFree(Sync lanesSync, Lane lane, MutableList<Lane> freeLanes) {
	freeLaneWaiters.put(lane, [lanesSync, freeLanes]);
}

class OnDemandThread(shared Lane lane) {
	
	value queue = LinkedBlockingDeque<Runnable?>();
	variable Boolean die = false;
	value running = AtomicBoolean(false);
	
	void loop() {
		print("Started loop of Lane ``lane.id``");
		while(!die) {
			try {
				value action = queue.poll(1M, TimeUnit.\iDAYS);
				if (exists action) {
					busyLanes.add(lane);
					action.run();
				}
			} catch (InterruptedException e) {
				print("Lane ``lane.id`` interrupted");
			} catch (e) {
				e.printStackTrace();
			} finally {
				if (queue.empty) {
					busyLanes.remove(lane);
					if (exists waiter = freeLaneWaiters[lane]) {
						waiter.first.syncExec(() => waiter[1].add(lane));
					}
				}
			}
		}
		threads.remove(lane.id);
		running.set(false);
		print("Thread for lane ``lane.id`` dying");
	}
	
	object looper satisfies Runnable {
		shared actual void run() {
			loop();
		}
	}
	
	shared Thread thread = Thread(looper, lane.id);
	thread.daemon = true;
	
	shared void runNext(Runnable toRun) {
		die = false;
		if (running.compareAndSet(false, true)) {
			thread.start();
		}
		queue.add(toRun);
	}
	
	shared Boolean isRunning() {
		return running.get();
	}
	
	shared void done() {
		die = true;
		running.set(false);
		thread.interrupt();
	}
	
}

shared void runSoonest(Lane lane, Runnable runnable) {
	initIfNecessary(lane).runNext(runnable);
}

shared Boolean stop(Lane lane) {
	if (exists thread = threads.get(lane.id)) {
		thread.done();
		return true;
	}
	return false;
}

shared Boolean isActive(Lane lane) {
	if (exists thread = threads.get(lane.id)) {
		return thread.isRunning();
	}
	return false;
}

shared Lane? currentLane() {
	Thread currentThread = Thread.currentThread();
	OnDemandThread? onDemandThread = threads.get(currentThread.name);
	if (exists onDemandThread, onDemandThread.thread === currentThread) {
		return onDemandThread.lane;
	}
	return null;
}

OnDemandThread initIfNecessary(Lane lane) {
	OnDemandThread thread = threads.get(lane.id) else OnDemandThread(lane);
	threads.put(lane.id, thread);
	return thread;
}

