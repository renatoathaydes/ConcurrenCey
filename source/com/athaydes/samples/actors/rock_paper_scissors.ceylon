import com.athaydes.concurrencey {
    Lane,
    Scheduler,
    ScheduledTask
}
import com.athaydes.concurrencey.actor {
    Sender,
    Actor
}

import java.util {
    Random
}

abstract class Move()
		of rock | paper | scissors | invalid {}

object rock extends Move() { string = "rock"; }
object paper extends Move() { string = "paper"; }
object scissors extends Move() { string = "scissors"; }
object invalid extends Move() { string = "invalid"; }

object referee {
	
	shared Boolean? isFirstMoveBetter(Move first, Move second) {
		if (first === second) { return null; }
		switch(first)
		case (rock) { return second === scissors; }
		case (paper) { return second === rock; }
		case (scissors) { return second === paper; }
		case (invalid) { throw; }
	}
}

class Play(shared Sender<Move> sender) {}

class Restart(shared Sender<Restart> sender, shared Boolean restart = false) {}

abstract class WatchTime(shared Sender<WatchTime> sender)
		of StartWatching | StopWatching {}

class StartWatching(Sender<WatchTime> sender) extends WatchTime(sender) {}
class StopWatching(Sender<WatchTime> sender) extends WatchTime(sender) {}


class Gui() extends Actor<String>(Lane("gui-lane")) {
	
	shared actual void react(String message) {
		print(message);
	}
	
}

class HumanPlayer() extends Actor<Play|Restart>(Lane("human-lane")) {
	
	void play(Sender<Move> sender) {
		value move = process.readLine();
		assert(exists move);
		switch(move.lowercased)
		case ("rock") {
			sender.send(rock);	
		} case("paper") {
			sender.send(paper);
		} case("scissors") {
			sender.send(scissors);
		} else {
			sender.send(invalid);
		}
	}
	
	void restart(Sender<Restart> sender) {
		value userAnswer = process.readLine();
		assert(exists userAnswer);
		sender.send(Restart(sender, userAnswer.lowercased != "stop"));
	}
	
	shared actual void react(Play|Restart message) {
		switch(message)
		case (is Play) { play(message.sender); }
		case (is Restart) { restart(message.sender); }
	}
	
}

class ComputerPlayer() extends Actor<Play>() {
	
	value random = Random();
	
	shared actual void react(Play message) {
		switch(random.nextInt(3))
		case (0) { message.sender.send(rock); }
		case (1) { message.sender.send(paper); }
		else { message.sender.send(scissors); }		
	}
	
}

class GameTimer(Sender<String> uiActor) extends Actor<WatchTime>() {
	
	value totalTime = 25_500;
	value scheduler = Scheduler(false);
	variable ScheduledTask? timerTask = null;
	variable Integer timeLeftToPlay = totalTime;
	
	shared actual void react(WatchTime message) {
		stopTimer();
		if (is StartWatching message) {
			timerTask = scheduler.scheduleAtFixedRate(1000, 5000, () =>
					updateTimer(message, timeLeftToPlay = timeLeftToPlay - 5000));
			assert(timerTask exists);
		}
	}
	
	void stopTimer() {
		if (exists t = timerTask) {
			t.cancel();
		}
		timeLeftToPlay = totalTime;
	}
	
	void updateTimer(WatchTime message, Integer timeLeft) {
		if (timeLeft <= 0) {
			message.sender.send(message);
		} else {
			uiActor.send("You have ``timeLeft/1000`` seconds to make a move");
		}
	}
	
}

class Coordinator() extends Actor<Restart|Move|WatchTime>() {
	
	Sender<String> gui = Gui();
	Sender<Play|Restart> human = HumanPlayer();
	Sender<Play> computer = ComputerPlayer();
	Sender<WatchTime> gameTimer = GameTimer(gui);
	value latestMoves = Array<Move?> { null, null };
	value wins = Array {0, 0, 0};
	
	shared void start() {
		gui.send("Please make your move. Type either 'rock', 'paper' or 'scissors'");
		latestMoves.set(0, null);
		latestMoves.set(1, null);
		gameTimer.send(StartWatching(this));
		human.send(Play(this));
	}
	
	void stop() {
		gui.send("Thank you for playing!");
		process.exit(0);
	}
	
	void showWinner() {
		gameTimer.send(StopWatching(this));
		assert(exists humanMove = latestMoves.first);
		assert(exists computerMove = latestMoves[1]);
		if (humanMove === invalid) {
			gui.send("Your move was not recognized!");
		} else {
			if (exists humanWins = referee.isFirstMoveBetter(humanMove, computerMove)) {
				if (humanWins) {
					wins.set(0, (wins[0] else 0) + 1);
					gui.send("You win!");
				} else {
					wins.set(1, (wins[1] else 0) + 1);
					gui.send("You lost, try again!");
				}
			} else {
				wins.set(2, (wins[2] else 0) + 1);
				gui.send("It's a draw!");
			}
		}
		gui.send("Score: You ``wins[0] else 0`` X ``wins[1] else 0`` Computer, Draws: ``wins[2] else 0``");
		gui.send("To play again, hit 'Enter'! To stop, type 'stop'.");
		human.send(Restart(this));
	}
	
	shared actual void react(Restart|Move|WatchTime message) {
		switch(message)
		case (is Restart) {
			if (message.restart) {
				start();
			} else {
				stop();
			}
		}
		case (is Move) {
			if (latestMoves.first is Null) {
				latestMoves.set(0, message);
				gui.send("Human played ``message``");
				if (message === invalid) {
					latestMoves.set(1, rock);
					showWinner();
				} else {
					computer.send(Play(this));
				}
			} else {
				latestMoves.set(1, message);
				gui.send("Machine played ``message``");
				showWinner();
			}
		}
		case (is WatchTime) {
			gui.send("Your time is over!");
			stop();
		}
	}
	
}


void run() {
	Coordinator().start();
}