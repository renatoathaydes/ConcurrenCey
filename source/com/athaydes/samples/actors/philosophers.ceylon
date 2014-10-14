import ceylon.collection {
    HashMap
}
import ceylon.time {
    now,
    Duration
}

import com.athaydes.concurrencey {
    Scheduler
}
import com.athaydes.concurrencey.actor {
    Actor
}

abstract class Side(shared Integer index) of left | right {}
object left extends Side(0) { string = "left"; }
object right extends Side(1) { string = "right"; }

abstract class State() of eating | hungry | thinking {}
object eating extends State() { string = "eating"; }
object hungry extends State() { string = "hungry"; }
object thinking extends State() { string = "thinking"; }

abstract class Waiting() of waiting {}
object waiting extends Waiting() {}

class Eat() {}
class Think() {}
class Fork(shared Integer index) {}
class Take(shared Philosopher philosopher, shared Side side) {}
class NotHungry(shared Philosopher philosopher) {}
class Talk() {}

class Waiter(Array<Fork|Philosopher?> table = Array<Fork|Philosopher?>({}))
		extends Actor<Fork|Take|NotHungry|Talk>() {
	
	value waitingPhilosophers = HashMap<Integer, Side>();
	
	shared actual void react(Fork|Take|NotHungry|Talk message) {
		switch(message)
		case (is Fork) { onFork(message); }
		case (is Take) { onTake(message); }
		case (is NotHungry) { onNotHungry(message); }
		case (is Talk) { onTalk(); }
	}
	
	function freeForks() => [ for (item in table) if (is Fork item) item ];
	
	void onTake(Take take) {
		value philosopher = take.philosopher;
		if (freeForks().size < 2) {
			print("``philosopher`` will have to wait for someone to return a fork");
			waitingPhilosophers.put(philosopher.index, take.side);
		} else {
			value wantedFork = forkFor(philosopher, take.side);
			if (exists wantedFork) {
				philosopher.send(wantedFork);
				table.set(wantedFork.index, null);
			} else {
				waitingPhilosophers.put(philosopher.index, take.side);
			}
		}
	}
	
	Integer wrapIndex(Integer index) =>
			index < 0 then table.size - 1 else (index >= table.size then 0 else index);
	
	Fork|Philosopher? itemAt(Integer index) =>
			table.get(wrapIndex(index));
	
	Fork? forkFor(Philosopher philosopher, Side side) {
		if (is Fork fork = itemAt(philosopher.index + (side === left then -1 else 1))) {
			return fork;
		}
		return null;
	}
	
	void onFork(Fork fork) {
		if (exists anyoneWaiting = whoWaitsFor(fork)) {
			print("Sending fork to ``anyoneWaiting``");
			anyoneWaiting.send(fork);
			table.set(fork.index, null);
			waitingPhilosophers.remove(anyoneWaiting.index);
		} else {
			print("No one waiting for fork ``fork.index``");
			table.set(fork.index, fork);
			if (freeForks().size >= 2) {
				for (waiting in waitingPhilosophers) {
					value philosopher = table.get(waiting.key);
					assert(is Philosopher philosopher);
					onTake(Take(philosopher, waiting.item));
				}
			}
		}
	}
	
	void onNotHungry(NotHungry message) {
		waitingPhilosophers.remove(message.philosopher.index);
	}
	
	void onTalk() =>
			print("Waiting: " + waitingPhilosophers.mapItems((Integer index, Side side) =>
			"``table[index] else "<>"`` waits for ``side`` fork!").string);
	
	Philosopher? whoWaitsFor(Fork fork) =>
			isWaitingOn(itemAt(fork.index - 1), right) else
	isWaitingOn(itemAt(fork.index + 1), left);
	
	Philosopher? isWaitingOn(Anything philosopher, Side wantedSide) {
		if (is Philosopher philosopher,
		exists side = waitingPhilosophers[philosopher.index],
		side === wantedSide) {
			return philosopher;
		}
		return null;
	}
	
}

class Philosopher(shared String name, shared Integer index)
		extends Actor<Eat|Think|Fork|Talk>() {
	
	shared variable State state = thinking;
	value forks = Array<Fork|Waiting?>({ null, null });
	shared variable Waiter waiter = Waiter();
	
	shared actual void react(Eat|Think|Fork|Talk message) {
		switch(message)
		case (is Eat) { onEat(); }
		case (is Think) { onThink(); }
		case (is Fork) { onFork(message); }
		case (is Talk) { onTalk(); }
	}
	
	void onEat() {
		switch(state)
		case (hungry) { print("``name`` asked to EAT, still hungry, waiting for forks"); }
		case (eating) { print("``name`` asked to EAT, but already eating"); }
		case (thinking) { getHungry(); }
	}
	
	void getHungry() {
		if (is Null leftFork = forks[left.index]) {
			waiter.send(Take(this, left));
			forks.set(left.index, waiting);	
		} else {
			print("ERROR: already has left fork but should start getting hungry now");
		}
		setState(hungry);
	}
	
	void onThink() {
		waiter.send(NotHungry(this));
		for (fork in forks) {
			if (is Fork fork) {
				waiter.send(fork);
			}
		}
		forks.set(left.index, null);
		forks.set(right.index, null);
		setState(thinking);
	}
	
	void onFork(Fork fork) {
		if (is Waiting leftFork = forks[left.index]) {
			print("``this`` accepted left fork");
			forks.set(left.index, fork);
			waiter.send(Take(this, right));
			forks.set(right.index, waiting);
		} else if (is Waiting rightFork = forks[right.index]) {
			print("``this`` accepted right fork");
			forks.set(right.index, fork);
			setState(eating);
		} else {
			print("``name`` doesn't need a fork but got one! Returning it!");
			waiter.send(fork);
		}
	}

	string => name;
	
	void onTalk() {
		function forkAsString(Fork|Waiting? fork) =>
				"``fork is Null then "empty" else (fork is Waiting then "waiting" else "fork")``";
		print("``string`` is ``state``, ``forkAsString(forks[left.index])`` on left hand
                and ``forkAsString(forks[right.index])`` on right hand".normalized);
	}
	
	void setState(State state) {
		this.state = state;
		print("``name `` is ``state``");
	}
	
	
}

shared void runPhilosophers() {
	value table = Array<Philosopher|Fork?>({
		Fork(0), Philosopher("Aristotle", 1),
		Fork(2), Philosopher("Descartes", 3),
		Fork(4), Philosopher("Foucault", 5),
		Fork(6), Philosopher("Nietzsche", 7),
		Fork(8), Philosopher("Rousseau", 9)
	});
	
	value waiter = Waiter(table);
	value philosophers = [ for (item in table) if (is Philosopher item) item ];
	for (philosopher in philosophers) { philosopher.waiter = waiter; }
	
	value orders = [ "eat", "think", "talk" ];
	
	print("Welcome to the philosophers dinner!
	       You can tell them what to do by providing the commands ``orders``.
	       The philosophers on the table are ``philosophers*.name``.
	       Indicate which philosopher should follow your order by the first letter of his name.
           Examples:
              eat A
              think R
           You can also ask the waiter to show who is waiting for forks:
              talk w
           Type 'quit' to exit.");
	
	value scheduler = Scheduler();
	
	variable Boolean done = false;
	while (!done) {
		value line = process.readLine();
		if (exists line) {
			value commands = line
					.trim((Character c) => ' ' == c)
					.lowercased
					.split();
			if (exists action = commands.first, action in orders,
				exists to = commands.rest.first, ! is Null initial = to.first) {
				if (initial.lowercased == 'w') {
					waiterCommand(action, waiter);
				} else if (exists philosopher = philosophers.find((Philosopher p) =>
					initial == (p.name.lowercased.first else ' '))) {
					philosopherCommand(action, philosopher);
				} else {
					print("Philosopher ``to`` does not exist, choose from: ``philosophers*.name``");
				}
			} else if (exists action = commands.first, action == "quit") {
				done = true;
			} else {
				print("Enter a command: ``orders`` + philosopher's initial");
			}
			
			if (!done) {
				scheduler.schedule([now().plus(Duration(1000))], () => print(prettify(table)));
			}
		} else {
			done = true;
		} 
		
	}
	
}

void waiterCommand(String action, Waiter waiter) {
	if (action == "talk") {
		waiter.send(Talk());
	} else {
		print("Waiter's only command is 'talk'... Try 'talk w'.");
	}
}

void philosopherCommand(String action, Philosopher philosopher) {
	switch(action)
	case("talk") { philosopher.send(Talk()); }
	case("think") { philosopher.send(Think()); }
	case ("eat") { philosopher.send(Eat()); }
	else { throw; }
}

String prettify(Array<Fork|Philosopher?> table) {
	value result = StringBuilder();
	result.append("--------- Table ---------").appendNewline();
	for (item in table) {
		switch(item)
		case (is Fork) { result.append(" X "); }
		case (is Philosopher) { result.append("``item.name``-``item.state``"); }
		case (is Null) { result.append(" _ "); }
	}
	return result.string;
}
