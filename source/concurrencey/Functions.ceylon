shared [Integer, Result] withTimer<Result>(Result() act) {
	value startTime = system.milliseconds;
	value result = act();
	return [system.milliseconds - startTime, result];
}
