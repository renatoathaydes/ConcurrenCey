import ceylon.collection {
	LinkedList
}

import concurrencey.internal {
	returnLaneWhenFree
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
	shared LaneStrategy laneStrategy = UnlimitedLanesStrategy())
		satisfies ActionRunner {
	
	shared actual Promise<Element> run<Element>(Action<Element> action) =>
			action.runOn(laneStrategy.provideLaneFor(action));
	
}

object laneIdGenerator {
	
	variable Integer laneCounter = 0;
	Lane laneProviderSyncLane = Lane("lane-provider-sync-lane");
	
	String laneId(Object+ cls) =>
		 "-".join({ for (c in cls) c.string }.chain({ (laneCounter++).string }));
	
	shared String generateId(Object+ cls) {
		value id = Action(() => laneId(*cls)).runOn(laneProviderSyncLane).syncGet();
		switch(id)
		case (is String) {
			return id;
		}
		case (is ComputationFailed) {
			throw Exception("Could not generate ID for Lane", id.exception);
		}
	}
	
}

String(Object+) generateId => laneIdGenerator.generateId;

"A strategy for allocating [[Lane]]s to [[Action]]s."
shared interface LaneStrategy {
	"Provides a [[Lane]] for the given [[Action]]."
	shared formal Lane provideLaneFor(Action<Anything> action);
}

"A [[LaneStrategy]] which always uses a single [[Lane]] to run all [[Action]]s."
shared class SingleLaneStrategy() satisfies LaneStrategy {
	value lane = Lane(generateId("single-lane-strategy"));
	provideLaneFor(Action<Anything> action) => lane;
}

"A [[LaneStrategy]] which only uses the provided number of [[Lane]]s to run [[Action]]s.
 Free Lanes are re-used to run new Actions. If all Lanes are busy at a given time, the
 runner will have to wait for a Lane to become idle again before it will be able to run
 any more Actions."
shared class LimitedLanesStrategy(shared Integer maximumLanes)
		satisfies LaneStrategy {
	
	value initialLanes = LinkedList({ for (i in 1..maximumLanes) Lane(
		generateId("limited-lanes", i)) });
	
	value lanes = LinkedList(initialLanes);
	
	Lane? virginLane() => initialLanes.removeFirst();
	
	Lane? nextLane() => lanes.removeFirst();
	
	Lane waitForFreeLane() {
		waitUntil(() => !lanes.empty, 1P);
		return nextVirginOrFreeLane();
	}
	
	Lane nextVirginOrFreeLane() =>
			virginLane() else nextLane() else waitForFreeLane();
	
	shared actual Lane provideLaneFor(Action<Anything> action) {
		value lane = nextVirginOrFreeLane();
		returnLaneWhenFree(lane, lanes);
		return lane;
	}
	
}

"A [[LaneStrategy]] which uses as many [[Lane]]s as necessary to run all provided
 [[Action]]s. Notice that although running Actions in parallel generaly speeds up
 the completion of all tasks, running a very large number of Actions in parallel
 may not provide much benefit due to scheduling overhead."
shared class UnlimitedLanesStrategy() satisfies LaneStrategy {
	
	value lanes = LinkedList<Lane>();
	
	Lane newLane() => Lane(generateId("no-limit-lanes"));
	
	Lane nextFreeLaneOrNewOne() => lanes.removeFirst() else newLane();
	
	shared actual Lane provideLaneFor(Action<Anything> action) {
		value lane = nextFreeLaneOrNewOne();
		returnLaneWhenFree(lane, lanes);
		return lane;
	}
	
}
