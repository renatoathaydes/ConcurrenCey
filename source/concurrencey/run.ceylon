import ceylon.test { assertEquals }




"Run the module `concurrencey`."
shared void run() {
	value runner = ActionRunner([
	Action(() => example("World")),
	Action(() => true)]);
	
	value promises = runner.startAndGetPromises();
	
	void checkResult(String|Boolean|ComputationFailed result) {
		switch(result)
		case (is String) { print("Got a String ``result``"); }
		case (is ComputationFailed) { print(result.exception); }
		case (is Boolean) { print("A Boolean ``result``"); }
	} 
	
	promises.first.onCompletion(checkResult);
	
	assertEquals(promises.first.get(), "Hello World");
	assert(exists second = promises[1], second.get() == true);
	
	value guiLane = Lane("GUI");
	value busLane = Lane("BUS");
	Action(updateWindows).runOn(guiLane);
	value recordsPromise = Action(loadRecordsFromDB).runOn(busLane);
	print(recordsPromise.get());
	
}

String example(String s) {
	return "Hello ``s``";
}

void updateWindows() {}
List<String> loadRecordsFromDB() { return []; }