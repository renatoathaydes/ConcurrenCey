import ceylon.collection {
	LinkedList
}
import ceylon.language {
	shared,
	default,
	Tuple,
	variable,
	formal,
	actual
}

import concurrencey {
	Promise,
	ComputationFailed
}
import concurrencey.internal {
	returnLaneWhenFree
}


import java.util.concurrent {
	CountDownLatch
}

"[[Action]] runners are able to run Actions. Although Actions 'know' how to run,
 it is often very useful to separate the logic required to orchestrate execution
 of Actions from the logic in which actions are actually dispatched."
shared abstract class ActionRunner() {
	
	"Runs the given [[Action]]s, possibly asynchrounously and in parallel,
	 returning a [[Promise]] which can be used to retrieve the result of
	 each Action."
	shared default [Promise<Element>+] runActions<Element, First, Rest>(
		Tuple<ActionBase<Element>, First, Rest> actions)
			given First satisfies ActionBase<Element>
			given Rest satisfies ActionBase<Element>[] {
		return [for (act in actions) run(act) ];
	}
	
	"Runs the given [[Action]]s, possibly in parallel, and block until all
	 Actions have completed, returning [[Promise]]s which can be used to retrieve the result of
	 each Action.
	 
	 The order of the returned Promises matches the order the given Actions (the order in which
	 the Actions are completed is not considered), except if several computations fail, in which
	 case, although the order of successfull results is maintained, the order of failures is not."
	shared default [Element|ComputationFailed*] runActionsAndWait<Element, First, Rest>(
		Tuple<ActionBase<Element>, First, Rest> actions)
			given First satisfies ActionBase<Element>
			given Rest satisfies ActionBase<Element>[] {
		value latch = CountDownLatch(actions.size);
		
		value collector = Array<Element|ComputationFailed?>({null}.repeat(actions.size));
		
		void captureResult([Integer, Element]|[Integer, ComputationFailed] result) {
			collector.set(result.first, result[1]);
			latch.countDown();
		}
		
		for (id -> act in entries(actions)) {
			run(IdAction(id, () => [id, act.syncRun()]))
					.onCompletion(captureResult);
		}
		
		latch.await();
		
		return collector.coalesced.sequence;
	}
	
	"Runs the given [[Action]], possibly in parallel, and block until it has completed.
	 The returned [[Promise]]s can be used to retrieve the result of the Action."
	shared default Element|ComputationFailed runAndWait<Element>(ActionBase<Element> action) {
		value latch = CountDownLatch(1);
		
		variable Element|ComputationFailed|NoValue result = noValue;
		
		void captureResult(Element|ComputationFailed toCapture) {
			result = toCapture;
			latch.countDown();
		}
		
		run(action).onCompletion(captureResult);
		
		latch.await();
		
		if (is Element|ComputationFailed final = result) {
			return final;
		}
		
		throw;
	}
	
	"Runs the given [[Action]], possibly asynchrounously, returning a
	 [[Promise]] which can be used to retrieve the result of the Action."
	shared formal Promise<Element, Failure> run<out Element, out Failure=ComputationFailed>(
		ActionBase<Element, Failure> action)
			given Failure satisfies Object;
	
}

"This runner can be used to run one or several [[Action]]s, possibly in parallel, according to
 the provided [[LaneStrategy]]."
shared class StrategyActionRunner(
	shared LaneStrategy laneStrategy = UnlimitedLanesStrategy())
		extends ActionRunner() {
	
	shared actual Promise<Element, Failure> run<out Element, out Failure=ComputationFailed>(
		ActionBase<Element, Failure> action)
			given Failure satisfies Object =>
			action.runOn(laneStrategy.provideLaneFor(action));
	
}

"A strategy for allocating [[Lane]]s to [[Action]]s."
shared interface LaneStrategy {
	"Provides a [[Lane]] for the given [[Action]]."
	shared formal Lane provideLaneFor(ActionBase<Anything, Object> action);
}

"A [[LaneStrategy]] which always uses a single [[Lane]] to run all [[Action]]s."
shared class SingleLaneStrategy() satisfies LaneStrategy {
	value lane = Lane("single-lane-strategy");
	provideLaneFor(ActionBase<Anything, Object> action) => lane;
}

"A [[LaneStrategy]] which only uses the provided number of [[Lane]]s to run [[Action]]s.
 Free Lanes are re-used to run new Actions. If all Lanes are busy at a given time, the
 runner will have to wait for a Lane to become idle again before it will be able to run
 any more Actions."
shared class LimitedLanesStrategy(shared Integer maximumLanes)
		satisfies LaneStrategy {
	
	value initialLanes = LinkedList({ for (i in 1..maximumLanes) Lane(
		"limited-lanes-``i``") });
	
	value lanes = LinkedList(initialLanes);
	
	Lane? virginLane() => initialLanes.removeFirst();
	
	Lane? nextLane() => lanes.removeFirst();
	
	Lane waitForFreeLane() {
		waitUntil(() => !lanes.empty, 1P);
		return nextVirginOrFreeLane();
	}
	
	Lane nextVirginOrFreeLane() =>
			virginLane() else nextLane() else waitForFreeLane();
	
	shared actual Lane provideLaneFor(ActionBase<Anything, Object> action) {
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
	
	Lane newLane() => Lane("no-limit-lanes");
	
	Lane nextFreeLaneOrNewOne() => lanes.removeFirst() else newLane();
	
	shared actual Lane provideLaneFor(ActionBase<Anything, Object> action) {
		value lane = nextFreeLaneOrNewOne();
		returnLaneWhenFree(lane, lanes);
		return lane;
	}
	
}
