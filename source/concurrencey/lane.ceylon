import concurrencey.internal {
	isLaneBusy, generateLaneId
}

"A Lane represents a Thread where [[concurrencey::Action]]s may run. A Lane is not exactly the
 same as a Java Thread. A Lane might discard its current Thread if it has been long
 idle, for example, and start a new one only when necessary.
 
 It is guaranteed, however, that actions running on the same Lane will never run simultaneously."
shared class Lane(
	"The name of this [[Lane]]. Names are not guaranteed to be unique, only IDs are."
	shared String name) {

	"The ID of this [[Lane]]."
	shared String id = generateLaneId(name);
	
	"Indicates whether this Lane is currently busy. Notice that even if this method returns
	 false, the Lane may get busy immediately after this invokation returns, which means there
	 is no guarantee the Lane will actually be free by the time an [[concurrencey::Action]] is submitted to
	 run on it."
	shared Boolean busy => isLaneBusy(this);
	
	shared actual Boolean equals(Object other) {
		if (is Lane other, this.id == other.id) {
			return true;
		}
		return false;
	}
	
	shared actual Integer hash => id.hash;
	
}
