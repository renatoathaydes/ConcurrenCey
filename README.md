#ConcurrenCey

ConcurrenCey is a Ceylon library that makes it trivial to write concurrent, multi-threaded code.

It is currently under active development. Please contact me if you would like to contribute!

Here's a quick example of what code written with ConcurrenCey looks like:

```ceylon
shared void run() {
	// run 2 actions in parallel
	value runner = ActionRunner([
		Action(() => expensiveComputation("World")),
		Action(() => Resource(verySlow).useIt())]);
	
	// start and get the Promises containing the results
	runner.run();
	value results = runner.results();
	
	assert(exists results);
	
	// get the results, blocking if necessary until they are ready
	assertEquals(results.first.get(), "Hello World");
	assert(exists second = results[1], second.get() == allGood);
}
```

## Getting started

You just need to add this declaration to your Ceylon module:

```ceylon
import concurrencey "0.0.1"
```

