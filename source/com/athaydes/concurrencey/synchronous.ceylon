import ceylon.time {
	Duration
}

import java.util.concurrent {
	TimeUnit,
	CountDownLatch
}


"Provides the result of an operation synchronously, ie. blocking."
shared interface SyncHasValue<out Result=Anything>
		satisfies HasValue<Result> {
	"Synchronously (blocking) get the value of this computation."
	throws(`class TimeoutException`, "if no value is set until the maximum wait is reached")
	shared formal Result syncGet(Duration maximumWait);
}

"Synchronous implementation of [[HasValue]] which allows blocking until a value is present."
shared class SynchronousValue<Result=Anything>()
		satisfies SyncHasValue<Result> & AcceptsValue<Result> {
	
	value promise = WritableOncePromise<Result>();
	value latch = CountDownLatch(1);
	
	"Blocks until a value is available. If a value was already available when this was called, returns the value
	 immediatelly, otherwise waits until it becomes available and returns it."
	throws(`class Exception`, "if the promise returns an instance of `NoValue`.")
	throws(`class TimeoutException`, "if the promise is not fullfilled within the timeout.")
	shared actual Result syncGet("Maximum duration to wait for a value." Duration maximumWait) {
		value done = latch.await(maximumWait.milliseconds, TimeUnit.\iMILLISECONDS);
		if (done) {
			value result = promise.getOrNoValue();
			if (is Result result) { return result; }
			if (is Exception result) { throw result; }
			throw Exception("Invalid internal state");
		} else {
			throw TimeoutException();
		}
	}
	
	getOrNoValue() => promise.getOrNoValue();
	
	shared actual void set(Result|Exception result) {
		promise.set(result);
		latch.countDown();
	}
	
}
