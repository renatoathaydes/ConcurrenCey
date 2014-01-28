import ceylon.test { assertEquals }




"Run the module `concurrencey`."
shared void run() {
	value runner = ActionRunner([
		Action(() => example("World")),
		Action(() => true)]);
	
	runner.run();
	value results = runner.results();
	
	assert(exists results);
	assertEquals(results.first.get(), "Hello World");
	assert(exists second = results[1], second.get() == true);
}

String example(String s) {
	return "Hello ``s``";
}
