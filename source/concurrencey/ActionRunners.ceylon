import concurrencey.internal { listenForFreeLane }

"This class can be used to run several [[Action]]s in parallel according to the
 provided [[LaneStrategy]]. The default LaneStrategy is [[unlimitedLanesStrategy]]."
shared class ActionRunner<out Element, out First, out Rest>(
	Tuple<Action<Element>, First, Rest> actions,
	LaneStrategy laneStrategy = unlimitedLanesStrategy)
		given First satisfies Action<Element>
		given Rest satisfies Action<Element>[]
{
	
	"Returns [[Promise]]s which will capture the result of each [[Action]]."
	shared [Promise<Element>+] startAndGetPromises() {
		value promises = [ for (act in actions ) act.runOn(
			laneStrategy.provideLaneFor(act)) ];
		return [ for (item in promises) item ];
	}
	
}



"A strategy for allocating [[Lane]]s to [[Action]]s."
shared interface LaneStrategy {
	"Provides a [[Lane]] for the given [[Action]]."
	shared formal Lane provideLaneFor(Action<Anything> action);
}

"A [[LaneStrategy]] which always uses a single [[Lane]] to run all [[Action]]s."
shared object singleLaneStrategy satisfies LaneStrategy {
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
		value promise = WritablePromise<Lane>();
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
shared object unlimitedLanesStrategy satisfies LaneStrategy {
	
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
