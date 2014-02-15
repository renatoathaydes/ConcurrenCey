import concurrencey {
	StrategyActionRunner,
	Action, Scheduler, withTimer
}
import concurrencey.actor {
	Sender,
	Actor
}

class Ball(shared Sender<Ball> sender) {}

class PingPong(Integer maxCount) extends Actor<Ball>() {
	shared variable Integer count = 0;
	shared actual void react(Ball ball) {
		count += 1;
		if (count < maxCount) {
			ball.sender.send(Ball(this));	
		}
	}
}

void runPerformanceTest() {
	value ping = PingPong(1000);
	value pong = PingPong(1000);
	
	withTimer(() =>	ping.send(Ball(pong)));
	
	
	print("Ping sent ``ping.count`` balls, Pong sent ``pong.count`` balls");
}
