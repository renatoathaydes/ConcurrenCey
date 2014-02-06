#ConcurrenCey

ConcurrenCey is a Ceylon library that makes it trivial to write concurrent, multi-threaded code.

It is currently under active development. Please contact me if you would like to contribute!

Concurrencey provides low-level as well as higher level concurrency constructs so that you can choose what style to use in your code.


## Getting started

You just need to add this declaration to your Ceylon module:

```ceylon
import concurrencey "0.0.1"
```

## Parallel computation

Run Actions in parallel using an `ActionRunner`:

```ceylon
function expensiveComputation() { ... }

// create a runner that can run Actions using different strategies 
value runner = StrategyActionRunner(unlimitedLanesStrategy);

value promises = runner.runActions([
	Action(expensiveComputation),
	Action(() => Resource(verySlow).useIt())]);

// callback to run when expensiveComputation completes
void handleResult(String|ComputationFailed result) {
	switch(result)
	case (is String) { print("Got a String ``result``"); }
	case (is ComputationFailed) { print(result.exception); }
}

promises.first.onCompletion(handleResult);

// can also get results synchronously (blocking!)
value results = runner.runActionsAndWait( ... );
```

You may control directly how to run Actions in different Lanes:

```ceylon
value guiLane = Lane("GUI");
value busLane = Lane("BUS");

Action(createWindows).runOn(guiLane);
value recordsPromise = Action(loadRecordsFromDB).runOn(busLane);
recordsPromise.onCompletion(updateWindows);
```

