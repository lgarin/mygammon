import ceylon.time {

	Instant,
	Duration
}
import ceylon.json {

	JsonObject=Object
}

shared final class GamePlayerStatistic() extends Object() {

	variable Integer _startedTurn = 0;
	shared Integer startedTurn => _startedTurn;

	variable Integer _dicePoints = 0;
	shared Integer dicePoints => _dicePoints;
	
	variable Integer _validMoves = 0;
	shared Integer validMoves => _validMoves;
	
	variable Integer _movedDistance = 0;
	shared Integer movedDistance => _movedDistance;
	
	variable Integer _undoneMoves = 0;
	shared Integer undoneMoves => _undoneMoves;
	
	variable Integer _boltHits = 0;
	shared Integer boltHits => _boltHits;
	
	variable Integer _playedJockers = 0;
	shared Integer playedJockers => _playedJockers;
	
	shared variable Integer remainingDistance = 0;
	
	variable Instant _turnStart = Instant(0);
	variable Duration _playTime = Duration(0);
	shared Duration playTime => _playTime;

	shared void turnStarted(DiceRoll diceRoll, Instant timestamp) {
		_startedTurn++;
		_dicePoints += diceRoll.dicePoints;
		_turnStart = timestamp;
	}
	
	shared void movedChecker(Integer distance, Boolean hitBolt) {
		if (distance < 0) {
			_undoneMoves++;
			_validMoves--;
			if (hitBolt) {
				_boltHits--;
			}
		} else {
			_validMoves++;
			if (hitBolt) {
				_boltHits++;
			}
		}
		_movedDistance += distance;
		
	}
	
	shared void turnEnded(Instant timestamp, Boolean jocker) {
		_playTime = Duration(_playTime.milliseconds + timestamp.millisecondsOfEpoch - _turnStart.millisecondsOfEpoch);
		_turnStart = Instant(0);
		if (jocker) {
			_playedJockers++;
		}
	}
	
	shared JsonObject toJson() {
		value result = JsonObject();
		result.put("startedTurn", startedTurn);
		result.put("dicePoints", dicePoints);
		result.put("validMoves", validMoves);
		result.put("movedDistance", movedDistance);
		result.put("undoneMoves", undoneMoves);
		result.put("boltHits", boltHits);
		result.put("playedJockers", playedJockers);
		result.put("remainingDistance", remainingDistance);
		result.put("playTime", playTime.milliseconds);
		return result;
	}
	
	shared void fromJson(JsonObject json) {
		_startedTurn = json.getInteger("startedTurn");
		_dicePoints = json.getInteger("dicePoints");
		_validMoves = json.getInteger("validMoves");
		_movedDistance = json.getInteger("movedDistance");
		_undoneMoves = json.getInteger("undoneMoves");
		_boltHits = json.getInteger("boltHits");
		_playedJockers = json.getInteger("playedJockers");
		remainingDistance = json.getInteger("remainingDistance");
		_playTime = Duration(json.getInteger("playTime"));
	}
	
	shared actual Boolean equals(Object that) {
		if (is GamePlayerStatistic that) {
			return _startedTurn==that._startedTurn && 
				_dicePoints==that._dicePoints && 
				_validMoves==that._validMoves && 
				_movedDistance==that._movedDistance && 
				_undoneMoves==that._undoneMoves && 
				_boltHits==that._boltHits && 
				_playedJockers==that._playedJockers && 
				remainingDistance==that.remainingDistance && 
				_turnStart==that._turnStart && 
				_playTime==that._playTime;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + _startedTurn;
		hash = 31*hash + _dicePoints;
		hash = 31*hash + _validMoves;
		hash = 31*hash + _movedDistance;
		hash = 31*hash + _undoneMoves;
		hash = 31*hash + _boltHits;
		hash = 31*hash + _playedJockers;
		hash = 31*hash + remainingDistance;
		hash = 31*hash + _turnStart.hash;
		hash = 31*hash + _playTime.hash;
		return hash;
	}
}


shared final class GameStatistic extends Object {
	
	variable Integer _initialDistance = 0;
	shared Integer initialDistance => _initialDistance;
	variable Integer _checkerCount = 0;
	shared Integer checkerCount => _checkerCount;
	
	value blackStatistic = GamePlayerStatistic();
	value whiteStatistic = GamePlayerStatistic();
	variable Instant _startTime = Instant(0);
	variable Instant _endTime = _startTime;
	
	shared new(Integer initialDistance, Integer checkerCount) extends Object() {
		_initialDistance = initialDistance;
		_checkerCount = checkerCount;
	}
	
	shared GamePlayerStatistic side(CheckerColor color) {
		return switch (color)
			case (black) blackStatistic
			case (white) whiteStatistic;
	}
	
	shared void gameStarted(Instant startTime) {
		_startTime = startTime;
	}
	
	shared void gameEnded(Instant endTime) {
		_endTime = endTime;
	}
	
	shared Duration duration => Duration(_endTime.millisecondsOfEpoch - _startTime.millisecondsOfEpoch);
	
	shared CheckerColor? winnerColor {
		if (blackStatistic.remainingDistance == 0 && whiteStatistic.remainingDistance > 0) {
			return black;
		} else if (whiteStatistic.remainingDistance == 0 && blackStatistic.remainingDistance > 0) {
			return white;
		} else {
			return null;
		}
	}
	shared Integer winnerScore => if (winnerColor exists) then (blackStatistic.remainingDistance - whiteStatistic.remainingDistance).magnitude else 0;
	
	shared JsonObject toJson() {
		value result = JsonObject();
		result.put("initialDistance", initialDistance);
		result.put("checkerCount", checkerCount);
		result.put("startTime", _startTime.millisecondsOfEpoch);
		result.put("endTime", _endTime.millisecondsOfEpoch);
		result.put("duration", duration.milliseconds);
		result.put("winnerColor", winnerColor?.name else null);
		result.put("winnerScore", winnerScore);
		result.put("blackStatistic", blackStatistic.toJson());
		result.put("whiteStatistic", whiteStatistic.toJson());
		return result;
	}
	
	shared new fromJson(JsonObject json) extends Object() {
		_initialDistance = json.getInteger("initialDistance");
		_checkerCount = json.getInteger("checkerCount");
		_startTime = Instant(json.getInteger("startTime"));
		_endTime = Instant(json.getInteger("endTime"));
		blackStatistic.fromJson(json.getObject("blackStatistic"));
		whiteStatistic.fromJson(json.getObject("whiteStatistic"));
	}
	
	// TODO optimize
	shared GameStatistic copy() => fromJson(toJson());
	
	shared actual Boolean equals(Object that) {
		if (is GameStatistic that) {
			return _startTime==that._startTime && 
				_initialDistance==that._initialDistance && 
				_checkerCount==that._checkerCount && 
				blackStatistic==that.blackStatistic && 
				whiteStatistic==that.whiteStatistic && 
				_endTime==that._endTime;
		}
		else {
			return false;
		}
	}
	
	shared actual Integer hash {
		variable value hash = 1;
		hash = 31*hash + _startTime.hash;
		hash = 31*hash + _initialDistance;
		hash = 31*hash + _checkerCount;
		hash = 31*hash + blackStatistic.hash;
		hash = 31*hash + whiteStatistic.hash;
		hash = 31*hash + _endTime.hash;
		return hash;
	}
}
