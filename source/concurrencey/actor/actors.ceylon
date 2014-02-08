import concurrencey {
	Lane,
	Action
}

Lane defaultActorLane = Lane("default-actor-lane");

"A Sender has the sole responsibility of sending Messages out.
 
 If the Sender needs to receive a response, the Message itself must
 include the Sender or an indirect way to allow for this."
shared interface Sender<in Message> {

	"Sends a message"
	shared formal void send(Message message);
	
}

"Base class of all Actors. By default, all Actors run in the same [[Lane]].
 To specify on which Lane this Actor should run, simply provide it to the
 constructor."
shared abstract class Actor<in Message>(
	"The lane where the [[Actor.react]] method of this Actor will be invoked."
	Lane actorLane = defaultActorLane)
		satisfies Sender<Message> {
	
	"User implementation code that defines the behavir of this Agent.
	 
	 **This method must not be called by user code. It should be used solely
	 by the ConcurrenCey Framework to ensure concurrency is handled correctly.**"
	shared formal void react(Message message);
	
	shared actual void send(Message message) =>
			Action(() => react(message)).runOn(actorLane);
	
}
