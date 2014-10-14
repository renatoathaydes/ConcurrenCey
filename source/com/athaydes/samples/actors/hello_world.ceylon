import ceylon.time {
	Duration
}

import com.athaydes.concurrencey {
	SynchronousValue,
	AcceptsValue, TimeoutException
}
import com.athaydes.concurrencey.actor {
	Actor,
	Sender
}

// message definitions

class HelloMessage(shared Sender<String> sender) {}
class Start(shared Sender<HelloMessage> actor) {}

// actor definitions

class HelloActor() extends Actor<HelloMessage>() {
	react(HelloMessage message) => message.sender.send("Hello ``message.sender``");
}

class Greeter(String name, AcceptsValue<String> sync) extends Actor<String|Start>() {
	shared actual void react(String|Start message) {
		switch(message)
		case (is String) { sync.set(message); }
		case (is Start) { message.actor.send(HelloMessage(this)); }
	}
	string => name;
}

"Runs the Hello World Example for Actors, which prints the famous message."
shared void runHello() {
	value waitForGreeting = SynchronousValue<String>();
	Sender<HelloMessage> hello = HelloActor();
	Sender<Start> greeter = Greeter("World", waitForGreeting);
	
	// send a start signal
	greeter.send(Start(hello));
	
	// block until we get our greeting (wait for a maximum of 2 seconds).
	// If you don't block or keep a non-deamon Thread alive,
	// as all ConcurrenCey Lanes run as daemons, the program may die
	// before any Actor does anything!
	try {
		value greeting = waitForGreeting.syncGet(Duration(2k));
		print(greeting);
	} catch (TimeoutException e) {
		print("The Actor did not send a greeting within 2 seconds!");
	}

}

