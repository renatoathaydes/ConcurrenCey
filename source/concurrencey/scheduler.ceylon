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

HashMap<Integer, TimerTask> timerTasksMap = HashMap<Integer, TimerTask>();

"A Task that has been scheduled to run in a [[Scheduler]]."
shared class ScheduledTask(
	"The determinate [[Instant]]s this task is scheduled to run,
	 or the initial Instant followed by the period for repeating tasks."
	shared [Instant+]|[Instant, Integer] scheduledInstants) {
	
	shared Integer id = idCreator.createId();

	"Cancel this task. If the task has already run or been cancelled, calling
	 this method has no effect."
	shared void cancel() {
		if (exists timerTask = timerTasksMap[id]) {
			timerTask.cancel();
			timerTasksMap.remove(id);
		}
	}
	
}

"A Scheduler can schedule tasks to run at later [[Instant]]s in time."
shared class Scheduler(
	"Set to false if you do not want to run the Scheduler thread as deamon."
	shared Boolean runAsDeamon = true) {
	
	value timer =  Timer(runAsDeamon);
	
	function scheduledTask([Instant+]|[Instant, Integer] instantsOrDelay, TimerTask timerTask) {
		value scheduledTask = ScheduledTask(instantsOrDelay);
		timerTasksMap.put(scheduledTask.id, timerTask);
		return scheduledTask;
	}

	"Schedules the given action to run at the given instants.
	 
	 Instants which are already in the past are treated as being the current
	 Instant."
	throws(`class ForbiddenInvokationException`, "if this Scheduler has been shut-down")
	shared ScheduledTask schedule([Instant+] instants, Anything action()) {
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
	
	"Schedules the given action to run starting from the given delay or startTime,
	 then repeatedly, with a delay between tasks determined by the given period.
	 
	 Delays smaller than 0 and startTime in the past are treated as being the current
	 Instant."
	throws(`class ForbiddenInvokationException`, "if this Scheduler has been shut-down")
	shared ScheduledTask scheduleAtFixedRate(
		Integer|Instant delayOrStartTime, Integer period, void action()) {
		value timerTask = task(action);
		
		value delay = delayFor(delayOrStartTime);
		try {
			timer.scheduleAtFixedRate(timerTask, max({0, delay}), period);
			return scheduledTask([Instant(system.milliseconds + delay), period], timerTask);	
		} catch (e) {
			throw ForbiddenInvokationException(
				"This Scheduler can no longer schedule new tasks", e);
		}
	}
	
	"Shuts down this Scheduler. Any task currently running will be allowed to terminate
	 gracefully.
	 
	 After this Scheduler is shut down, trying to schedule new tasks is considered an error."
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