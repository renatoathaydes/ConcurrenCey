import java.util.concurrent.locks { ReentrantLock }


shared class IdException(shared Integer id, shared actual Exception cause)
		extends Exception("Exception with ID=``id``", cause) {}

shared class TimeoutException(shared actual String message = "")
		extends Exception(message) {}

shared class ForbiddenInvokationException(String message = "")
		extends Exception(message) {}

"Indicates that a value has not been set yet for a [[HasValue]]."
shared abstract class NoValue() of noValue {}

shared object noValue extends NoValue() {}

"Allows the synchronized execution of a Callable."
shared class Sync(
	"`true` if this Sync should use a fair ordering policy."
	shared Boolean fair = false) {
	
	value lock = ReentrantLock(fair);
	
	"Executes the given Callable, ensuring only a single Thread or [[Lane]] can
	 enter execution at a given time.
	 
	 The current Thread may be interrupted before or during execution."
	shared Result syncExec<Result>(Result() callable) {
		lock.lockInterruptibly();
		try {
			return callable();
		} finally {
			lock.unlock();
		}
	}

	"Runs the given Action, ensuring only a single Thread or [[Lane]] can
	 enter execution at a given time.
	 
	 The current Thread may be interrupted before or during execution."	
	shared Result syncRun<Result>(Action<Result> action) {
		lock.lockInterruptibly();
		try {
			return action.syncRun();
		} finally {
			lock.unlock();
		}
	}
	
}
