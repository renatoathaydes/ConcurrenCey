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

There are two ways you can use ConcurrenCey:

* Actor Model: the design constraints imposed by this model nearly eliminates the need to use concurrency control. ConcurrenCey enables you do use Actors in a very simple way. 
* Low-level control of execution: more traditional way of dealing with concurrency. However, ConcurrenCey makes it much simpler to deal with the unavoidable complexity of concurrent systems when compared to Java's approach.

Notice that the two approaches are not mutually-exclusive! It makes sense to limit yourself to using the most appropriate techniques for your particular case, but sometimes the best technique might involve a mix of the two.

## Actor Model

To use ConcurrenCey Actors, you only need to sub-class the ``Actor`` class and implement the ``react`` method, as shown below (this is an extract from one of the [actors samples](source/samples/actors/rock_paper_scissors.ceylon), which shows an implementation of the game Rock-Paper-Scissors using ConcurrenCey Actors):

```ceylon
class ComputerPlayer() extends Actor<Play>() {
	
	value random = Random();
	
	shared actual void react(Play message) {
		switch(random.nextInt(3))
		case (0) { message.sender.send(rock); }
		case (1) { message.sender.send(paper); }
		else { message.sender.send(scissors); }		
	}
	
}
```

By default, all Actors will run on the same ``Lane`` (this may change later), however, if you want to, you may specify on which ``Lane`` each Actor will run by giving it one through the constructor:

```ceylon
class Gui() extends Actor<String>(Lane("gui-lane")) { ... }
```

Actors are generic to allow them to handle any type of message. For example, an Agent can be used to handle several types of Messages by the use of Ceylon's union types:

```ceylon
class Coordinator() extends Actor<Restart|Move|WatchTime>() { ... }
```

It is advisable to keep the number of Message types an Actor handles to a minimum. This is in line with the single-responsibility principle.

Even though the ``react`` method of Actors is ``shared`` (so that you can refine it), it should only be called by the ConcurrenCey framework in order to maintain guarantees provided by the Actors model.

For this reason, you should always keep references to Actors through the ``Sender`` interface, which only exposes the ``send`` method.

```ceylon
Sender<String> gui = Gui();
Sender<Play|Restart> human = HumanPlayer();
Sender<Play> computer = ComputerPlayer();
```

Ideally, you should only keep references (even to ``Senders``) in the central point of your application. Most of the time, the only way to communicate with another Agent should be by replying to Messages sent by them. To ensure this is the case, you most likely want to avoid having ``shared`` methods inside your ``Actors`` (do not call methods, send a Message!).

> If you want to quickly get started with Actors, have a look at the [Hello World sample](source/samples/actors/hello_world.ceylon).

The Actor Model may seem quite restrictive at first sight, but with a little practice it becomes quite natural to program using it! If your application can be divided into many separate logical parts which interact with each other through limited and well-defined units of information (ie. messages), then you certainly should consider using the Actor Model.

However, it may not always be the best choice for your application. In cases you need more flexibility, or even higher performance, you can use the lower-level constructs provided by ConcurrenCey!

## Low-level control of execution

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

### Blocking, when you have to...

Blocking may not always be a good idea, but sometimes it is unavoidable.
When you need to block until something happens, you can use ``SynchronousValue``:

```ceylon
value syncValue = SynchronousValue<String>();

// give the syncValue to an Actor, for example, to notify us of something (like terminate execution)
value actor = MyActor(syncValue);
// more actors and other setup
...
// now finally wait until the Actor notifies us
print("The actor says ``syncValue.syncGet(Duration(10k))``");
```

This can be used to keep the main Thread sleeping while the actors do their jobs. Once we receive the signal from one of our Actors,
execution continues from the point where we called ``syncGet``. If there's no user Threads still alive (all ``ConcurrenCey`` Lanes run
as deamons), the program will terminate and the JVM will shutdown.

> Another way of blocking is to use ``ActionRunner#runAndWait`` or ``ActionRunner#runActionsAndWait``


### Scheduling tasks

The class ``Scheduler`` allows the scheduling of tasks.

For example, to schedule a task to run in 50ms and then 2 hours from now:

```ceylon
value scheduler = Scheduler(); // Scheduler(false) to not run as deamon
value checkTime = Action(() => system.milliseconds);
value inAMoment = Instant(system.milliseconds + 50);
value in2hours = now().plus(Period { hours = 2; });
scheduler.schedule([inAMoment, in2hours], () => checkTime.runOn(testLane));
```

For repeating tasks, you can use ``scheduleAtFixedRate`` (example of scheduling an Action to run starting inAMoment, then repeating every 25 milliseconds):

```ceylon
value task = scheduler.scheduleAtFixedRate(
		inAMoment, 25, () => checkTime.runOn(testLane));

// much later
task.cancel();
```

### Collections

Due to the nature of concurrent applications, it is common to have mutable collections which you need to "observe", ie. to do something when the collection changes.

For this purpose, ConcurrenCey offers the ``ObservableLinkedList`` class:

```ceylon
value list = ObservableLinkedList<String>();
list.observe(void(Exception|ListEvent<String> event) {
	switch(event)
	case (is AddEvent<String>) { onAdd(event); }
	case (is RemoveEvent<String>) { onRemove(event); }
	case (is ReplaceEvent<String>) { onReplace(event); }
	case (is Exception) { throw event; }
});
```

Notice that the ObservableLinkedList is not thread-safe. To make it thread-safe, use ``Sync`` on all access to the list.

> Thread-safe collections are, in my opinion, just too dangerous and easy to misuse to be worth having.
> Far better is to use normal collections in a Thread-safe way, which is easy with ConcurrenCey anyway!

