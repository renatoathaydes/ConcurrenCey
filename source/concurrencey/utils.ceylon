

"The result of a computation which has not completed successfully."
shared class ComputationFailed(
	shared Exception exception,
	shared String reason = "") {}

shared class ComputationFailedWithId(
	shared Integer id,
	Exception exception,
	String reason = "") extends ComputationFailed(exception, reason) {}

shared class TimeoutException(shared actual String message = "")
		extends Exception(message) {}

"Indicates that a value has not been set yet for a [[HasValue]]."
shared abstract class NoValue() of noValue {}

shared object noValue extends NoValue() {}
