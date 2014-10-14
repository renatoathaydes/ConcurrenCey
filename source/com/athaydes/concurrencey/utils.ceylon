import java.util.concurrent.locks {
    ReentrantLock
}

"Exception that can be identified by an ID. Used in conjuction with `IdAction`."
see(`class IdAction`)
shared class IdException("The ID of this Exception." shared Integer id, Exception cause)
		extends Exception("Exception with ID=``id``", cause) {}

"Exception that is thrown when a timeout occurs."
shared class TimeoutException("Error message." shared actual String message = "")
		extends Exception(message) {}

"Exception thrown when a method is invoked on an object whose current state does not allow that."
shared class ForbiddenInvokationException(
	String message = "",
	Exception? exception = null)
		extends Exception(message, exception) {}

"Indicates that a value has not been set yet for a [[HasValue]]."
shared abstract class NoValue() of noValue {}

"Single instance of type `NoValue`"
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
