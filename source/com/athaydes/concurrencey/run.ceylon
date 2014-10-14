

"Run the module `concurrencey`. This is just an artificial example to show how ConcurrenCey may be used."
shared void run() {
	value runner = StrategyActionRunner();
	
	value promises = runner.runActions([
		Action(() => example("World")),
		Action(() => true)]);
	
	void checkResult(String|Boolean|Exception result) {
		switch(result)
		case (is String) { print("Got a String ``result``"); }
		case (is Exception) { print(result); }
		case (is Boolean) { print("A Boolean ``result``"); }
	} 
	
	promises.first.onCompletion(checkResult);
	
	assert(exists second = promises[1]);
	
	// sychronously waiting for a value - useful on tests, but blocking can be bad!
	waitUntil(() => second.getOrNoValue() == true);
	
	value guiLane = Lane("GUI");
	value busLane = Lane("BUS");
	Action(updateWindows).runOn(guiLane);
	Action(loadRecordsFromDB).runOn(busLane);
	
}

String example(String s) {
	return "Hello ``s``";
}

void updateWindows() {}
List<String> loadRecordsFromDB() { return []; }