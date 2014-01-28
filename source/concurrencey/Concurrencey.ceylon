import concurrencey.internal {
	runSoonest,
	isLaneBusy,
	listenForFreeLane
}

import java.lang {
	Runnable
}
import java.util.concurrent {
	LinkedBlockingDeque,
	TimeUnit
}

"The result of a computation which either has not yet been started
 or has not completed successfully."
abstract shared class ValueMissing(shared String reason)
of ComputationNotStarted | ComputationFailed {}

shared class ComputationNotStarted(String reason) extends ValueMissing(reason) {}

shared class ComputationFailed(shared Exception exception)
		extends ValueMissing(exception.message) {}

"A computation result destination"
shared interface AcceptsValue<in Result> {
	"Sets the result of a computation"
	shared formal void set(Result|ValueMissing result);
}

"A computation result source"
shared interface HasValue<out Result> {
	"Returns the result of a computation, or [[ValueMissing]] if the
	 computation has not started yet or not completed successfully"
	shared formal Result|ValueMissing get();
}

"A Promise represents the future result of a computation which may or may not
 ever complete, and may complete successfully or fail."
shared class Promise<Result>()
		satisfies HasValue<Result>&AcceptsValue<Result> {
	
	value queue = LinkedBlockingDeque<Result|ValueMissing?>(1);
	variable {Anything(Result|ValueMissing)*} listeners = {};

	shared actual void set(Result|ValueMissing result) {
		if (!queue.empty) {
			queue.remove();
		}
		queue.add(result);
	}
	
	"Returns the result of an operation, blocking until the operation is
	 completed if necessary."
	shared actual Result|ValueMissing get() {
		value item = queue.poll(1M, TimeUnit.\iDAYS);
		if (exists item) {
			queue.add(item);
			return item;
		}
		return ComputationFailed(Exception("Timeout while waiting for result"));
	}
	
	shared Boolean hasValue() {
		return !queue.empty;
	}
	
	shared void onCompletion(Anything(Result|ValueMissing) listener) {
		listeners = listeners.chain({listener});
	}
	
	shared Boolean stopListening(Anything(Result|ValueMissing) listener) {
		value size = listeners.size;
		listeners = listeners.filter((Anything(Result|ValueMissing) item) => item != listener);
		return size > listeners.size;
	}
	
}

"A Lane represents a Thread where [[Action]]s may run. The mapping is not 1-1,
 which means that a Lane might discard previously used Threads and start a new
 one in order to save resources, or re-use an idle Thread for efficiency."
shared class Lane(shared String name) {
	
	shared Boolean busy => isLaneBusy(this);
	
	shared actual Boolean equals(Object other) {
		if (is Lane other, this.name == other.name) {
			return true;
		}
		return false;
	}
	
	shared actual Integer hash => name.hash;
	
}

"An entity which can be run on a [[Lane]]."
shared interface LaneRunnable<out Result> {
	"Runs this entity on a [[Lane]]."
	shared formal HasValue<Result> runOn(Lane lane);
}

"An Action represents a computation which can be run in one or more [[Lane]]s."
shared class Action<out Result>(Result() act)
		satisfies LaneRunnable<Result> {
	
	shared actual HasValue<Result> runOn(Lane lane) {
		value promise = Promise<Result>();
		object runnable satisfies Runnable {
			shared actual void run() {
				try {
					promise.set(act());
				} catch (e) {
					e.printStackTrace();
					promise.set(ComputationFailed(e));
				}
			}
		}
		runSoonest(lane, runnable);
		return promise;
	}
	
}

"A strategy for allocating [[Lane]]s to [[Action]]s."
shared interface LaneStrategy {
	"Provides a [[Lane]] for the given [[Action]]."
	shared formal Lane provideLaneFor(Action<Anything> action);
}

"A [[LaneStrategy]] which always uses a single [[Lane]] to run all [[Action]]s."
shared class SingleLaneStrategy()
		satisfies LaneStrategy {
	value lane = Lane("single-lane");
	shared actual Lane provideLaneFor(Action<Anything> action) => lane;
}

"A [[LaneStrategy]] which only uses the provided number of [[Lane]]s to run [[Action]]s.
 Free Lanes are re-used to run new Actions. If all Lanes are busy at a given time, the
 runner will have to wait for a Lane to become idle again before it will be able to run
 any more Actions."
shared class LimitedLanesStrategy(shared Integer maximumLanes)
		satisfies LaneStrategy {
	
	value lanes = [ for (i in 1..maximumLanes) Lane("limited-lanes-item-``i``") ];
	
	shared actual Lane provideLaneFor(Action<Anything> action) {
		value freeLane = lanes.find((Lane lane) => !lane.busy);
		return freeLane else waitForFreeLane();
	}
	
	Lane waitForFreeLane() {
		value promise = Promise<Lane>();
		void receiveFreeLane(Lane lane) {
			promise.set(lane);
		}
		listenForFreeLane(receiveFreeLane, lanes);
		if (is Lane result = promise.get()) {
			return result;
		} else {
			throw Exception("Problem retrieving a free lane");
		}
	}
}

"A [[LaneStrategy]] which uses as many [[Lane]]s as necessary to run all provided
 [[Action]]s. Notice that it may not be faster to run a large number of Actions all
 in parallel because of the overhead of scheduling execution, for example."
shared class UnlimitedLanesStrategy() satisfies LaneStrategy {
	
	variable Integer count = 1;
	String newLaneName => "no-limit-lanes-item-``count++``";
	variable {Lane+} lanes = { Lane(newLaneName) };
	
	shared actual Lane provideLaneFor(Action<Anything> action) {
		value freeLanes = lanes.filter((Lane lane) => !lane.busy);
		if (is Lane free = freeLanes.first) {
			return free;
		}
		lanes = lanes.chain({ Lane(newLaneName) });
		return lanes.last;
	}
	
	
}

"This class can be used to run several [[Action]]s in parallel according to the
 provided [[LaneStrategy]]. The default LaneStrategy is [[UnlimitedLanesStrategy]]."
shared class ActionRunner<out Element, out First, out Rest>(
	Tuple<Action<Element>, First, Rest> actions,
	LaneStrategy laneStrategy = UnlimitedLanesStrategy())
		given First satisfies Action<Element>
		given Rest satisfies Action<Element>[]
{
	
	variable [HasValue<Element>+]? promises = null;
	
	"Start running all [[Action]]s using the provided [[LaneStrategy]]."
	shared void run() {
		promises = [ for (act in actions ) act.runOn(
			laneStrategy.provideLaneFor(act)) ];
	}
	
	"Returns [[Promise]]s with the result of each [[Action]]."
	shared [HasValue<Element>+]? results() {
		if (exists p = promises) {
			return [ for (item in p) item ];
		}
		return null;
	}
	
}

