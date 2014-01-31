import concurrencey.internal {
	captureNextFreedLane
}

import java.util.concurrent.atomic {
	AtomicInteger
}

"[[Action]] runners are able to run Actions. Although Actions 'know' how to run themselves,
 it is often very useful to separate the logic required to orchestrate execution of Actions from
 the logic in which actions are actually dispatched."
shared interface ActionRunner {
	
	shared default [Promise<Element>+] runActions<Element, First, Rest>(
		Tuple<Action<Element>, First, Rest> actions)
			given First satisfies Action<Element>
			given Rest satisfies Action<Element>[] {
		return [for (act in actions) run(act) ];
	}
	
	shared formal Promise<Element> run<Element>(Action<Element> action);
	
}

"This runner can be used to run one or several [[Action]]s, possibly in parallel, according to
 the provided [[LaneStrategy]]."
shared class StrategyActionRunner(
	shared LaneStrategy laneStrategy = unlimitedLanesStrategy)
		satisfies ActionRunner {
	
	shared actual Promise<Element> run<Element>(Action<Element> action) =>
			action.runOn(laneStrategy.provideLaneFor(action));
	
}

AtomicInteger laneIdCounter = AtomicInteger();

String laneId(Object+ cls) {
	value prefix = cls.fold("strategy", (Object s1, Object s2) => "``s1``-``s2``");
	return "``prefix``-``laneIdCounter.incrementAndGet()``";
}

Lane syncLane = Lane("action-runners-sync-lane");

Lane runLaneProvideAction(Action<Lane> laneAction) {
	value promise = laneAction.runOn(syncLane);
	if (is Lane lane = promise.syncGet()) {
		return lane;
	}
	throw Exception("Could not provide lane: ``promise.syncGet()``");
}

"A strategy for allocating [[Lane]]s to [[Action]]s."
shared interface LaneStrategy {
	"Provides a [[Lane]] for the given [[Action]]."
	shared formal Lane provideLaneFor(Action<Anything> action);
}

"A [[LaneStrategy]] which always uses a single [[Lane]] to run all [[Action]]s."
shared object singleLaneStrategy satisfies LaneStrategy {
	value lane = Lane(laneId("single-lanes"));
	shared actual Lane provideLaneFor(Action<Anything> action) => lane;
}

"A [[LaneStrategy]] which only uses the provided number of [[Lane]]s to run [[Action]]s.
 Free Lanes are re-used to run new Actions. If all Lanes are busy at a given time, the
 runner will have to wait for a Lane to become idle again before it will be able to run
 any more Actions."
shared class LimitedLanesStrategy(shared Integer maximumLanes)
		satisfies LaneStrategy {
	
	value lanes = [ for (i in 1..maximumLanes) Lane(laneId("limited-lanes", i)) ];
	
	Lane? freeLane() => lanes.find((Lane lane) => !lane.busy);
	
	Lane waitForFreeLane() {
		value promise = WritablePromise<Lane>();
		void receiveFreeLane(Lane lane) {
			promise.set(lane);
		}
		
		captureNextFreedLane(receiveFreeLane, lanes);
		
		if (exists lane = freeLane()) {
			return lane;
		}
		
		if (is Lane result = promise.syncGet()) {
			return result;
		}
		throw Exception("Problem retrieving a free lane");
	}
	
	value limitedLanesProvideAction = Action<Lane>(() => freeLane() else waitForFreeLane());
	
	shared actual Lane provideLaneFor(Action<Anything> action) {
		return runLaneProvideAction(limitedLanesProvideAction);
	}
}

"A [[LaneStrategy]] which uses as many [[Lane]]s as necessary to run all provided
 [[Action]]s. Notice that it may not be faster to run a large number of Actions all
 in parallel because of the overhead of scheduling execution, for example."
shared object unlimitedLanesStrategy satisfies LaneStrategy {
	
	variable {Lane+} lanes = { Lane(laneId("no-limit-lanes")) };
	
	Lane nextFreeLaneOrNewOne() {
		value freeLanes = lanes.filter((Lane lane) => !lane.busy);
		if (is Lane free = freeLanes.first) {
			return free;
		}
		lanes = lanes.chain({ Lane(laneId("no-limit-lanes")) });
		return lanes.last;
	}
	
	value unlimitedProvideAction = Action(() => nextFreeLaneOrNewOne());
	
	shared actual Lane provideLaneFor(Action<Anything> action) {
		return runLaneProvideAction(unlimitedProvideAction);
	}
	
}
