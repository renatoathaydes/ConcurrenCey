import ceylon.collection {
	HashMap
}
import ceylon.time {
	Instant
}

import concurrencey.internal {
	idCreator
}

import java.util {
	Timer,
	TimerTask
}

HashMap<ScheduledTask,TimerTask> timerTasksMap = HashMap<ScheduledTask,TimerTask>();

shared class ScheduledTask(
	"The determinate [[Instant]]s this task is scheduled to run,
	 or the initial Instant followed by the period for repeating tasks."
	shared [Instant+]|[Instant, Integer] scheduledInstants) {
	value id = idCreator.createId();
	
	shared void cancel() {
		if (exists timerTask = timerTasksMap[this]) {
			timerTask.cancel();
		}
	}
	
	hash = id;
	
	shared actual Boolean equals(Object other) {
		if (is ScheduledTask other) {
			return other.id == this.id;
		}
		return false;
	}
	
}

shared class Scheduler(
	"Set to false if you do not want to run the Scheduler thread as deamon."
	shared Boolean runAsDeamon = true) {
	
	value timer =  Timer(runAsDeamon);
	
	function scheduledTask([Instant+]|[Instant, Integer] instantsOrDelay, TimerTask timerTask) {
		value scheduledTask = ScheduledTask(instantsOrDelay);
		timerTasksMap.put(scheduledTask, timerTask);
		return scheduledTask;
	}
	
	shared ScheduledTask schedule([Instant+] instants, void action()) {
		value timerTask = task(action);
		for (instant in instants) {
			value delay = instant.millisecondsOfEpoch - system.milliseconds;
			timer.schedule(timerTask, max({ delay, 0 }));
		}
		return scheduledTask(instants, timerTask);
	}
	
	function delayFor(Integer|Instant delayOrStartTime) {
		switch(delayOrStartTime)
		case (is Integer) {
			return delayOrStartTime;
		}
		case (is Instant) {
			return delayOrStartTime.millisecondsOfEpoch - system.milliseconds;
		}
	}
	
	shared ScheduledTask scheduleAtFixedRate(
		Integer|Instant delayOrStartTime, Integer period, void action()) {
		value timerTask = task(action);
		
		value delay = delayFor(delayOrStartTime);
		timer.scheduleAtFixedRate(timerTask, max({0, delay}), period);
		return scheduledTask([Instant(system.milliseconds + delay), period], timerTask);
	}
	
	shared void shutDown() {
		timer.cancel();
	}
	
	TimerTask task(void action()) {
		object task extends TimerTask() {
			run() => action();
		}
		return task;
	}
	
}