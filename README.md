#ConcurrenCey

ConcurrenCey is a Ceylon library that makes it trivial to write concurrent, multi-threaded code.

It is currently under active development. Please contact me if you would like to contribute!

Concurrencey provides low-level as well as higher level concurrency constructs so that you can choose what style to use in your code.


## Getting started

You just need to add this declaration to your Ceylon module:

```ceylon
import concurrencey "0.0.1"
```

## How to use

Concurrencey solves the problem of executing concurrent code (ie. code which can run in parallel) by providing a number of useful constructs which are easy to use, while at the same time allowing all the flexibility required to solve even the most challenging issues.

A ``Lane`` represents a thread of execution where ``Action``s may run.

> Note: Lanes always have a backing Thread, but the Threads may be discarded or re-created to maximize resources utilization.

``Action``s are light-weight units of execution which may run at most once. Although you can run ``Action``s directly, it is much more flexible to use a ``StrategyActionRunner`` to do the job.

### StrategyActionRunner

An ``StrategyActionRunner`` may use one of the following strategies to run ``Action``s:

  * ``UnlimitedLanesStrategy``: will use as many ``Lanes`` as possible.
  * ``LimitedLanesStrategy``: use at most a pre-defined number of ``Lane``s.
  * ``SingleLaneStrategy``: ensures the use of a single ``Lane``.

Example of running ``Action``s using a ``StrategyActionRunner``:

```ceylon
value runner = StrategyActionRunner(); // UnlimitedLanesStrategy by default

value promises = runner.runActions([
	Action(() => someMethod("arg")),
	Action(anotherFunction) ]);

promises.first.onCompletion(useSomeMethodResult);
```

Notice that when you run actions, you usually do not get the results back directly. You get a ``Promise`` that you can use to get the results asynchronously (by giving the Promise an ``onCompletion`` function).

In the rare cases where you must wait for the results before being able to proceed, you can use the methods which explicitly say ``runAndWait``:

```ceylon
value results = runner.runActionsAndWait([
	Action(() => someMethod("arg")),
	Action(anotherFunction) ]);
```

### Using Lanes and Actions directly

You may also control directly how to run Actions in different Lanes:

```ceylon
value guiLane = Lane("GUI");
value busLane = Lane("BUS");

Action(createWindows).runOn(guiLane);
value recordsPromise = Action(loadRecordsFromDB).runOn(busLane);
recordsPromise.onCompletion(updateWindows);
```

### Using third-party Threads as Lanes

You can create your own ``ActionRunner``s in order to allow the use of third-party Threads within the ConcurrenCey framework.

Here's an example of how you would use ConcurrenCey together with JavaFX:


```ceylon
object javaFxActionRunner extends ActionRunner() {
	
	Promise<Element> runOnJavaFxThread<Element>(Action<Element> action) {
		object toRun satisfies Runnable {
			run() => action.syncRun();
		}
		Platform.runLater(toRun);
		return action.promise;
	}
	
	shared actual Promise<Element> run<Element>(Action<Element> action)
			=> runOnJavaFxThread(action);
	
}

String updateGuiFields() { ... }
void notifyUser(String|Exception message) { ... }

value guiFieldsUpdated = javaFxActionRunner.run(Action(updateGuiFields));
guiFieldsUpdated.onCompletion(notifyUser);
```

### Synchronizing execution

If you want, you can avoid the use of ``Action``s and ``Lane``s and use a style more similar to ``Java``'s synchronized blocks:

```ceylon
value resource = ...
value resourceSync = Sync();

resourceSync.syncExec(() => useResourceSafely(resource));
```

Because only a single Thread is guaranteed to execute the function passed to ``syncExec`` at a given time, ``Sync`` allows sharing resources as if in a single-threaded environment.

If you must avoid starvation in your system, you can enable fairness (at a performance cost) by calling the constructor with ``Sync(true)``.

Notice that using ``Sync`` with fairness activated achieves similar results as using a ``StrategyActionRunner`` with the ``SingleLaneStrategy``.


