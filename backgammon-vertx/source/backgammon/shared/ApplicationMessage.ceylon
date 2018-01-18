import ceylon.json {

	Object
}
import ceylon.collection {

	HashMap
}
import ceylon.language.meta {

	type
}

shared sealed interface ApplicationMessage {
	shared formal Object toJson();
	string => toJson().string;
	shared default Boolean mutation => true;
}

shared sealed interface StatusResponseMessage {
	shared formal Boolean success;
}

shared object applicationMessages {
	value parserMap = HashMap<String,ApplicationMessage(Object)>();
	
	void registerParser<MessageClass>(MessageClass(Object) parser) given MessageClass satisfies ApplicationMessage {
		parserMap.put(`MessageClass`.string.substring(`module`.name.size + 2), parser);
	}
	
	shared MessageClass? parse<out MessageClass>(Object json) given MessageClass satisfies ApplicationMessage {
		if (exists typeName = json.getStringOrNull("class"), exists parser = parserMap[typeName]) {
			if (is MessageClass result = parser(json)) {
				return result;
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
	
	shared Object format<in MessageClass>(MessageClass message) given MessageClass satisfies ApplicationMessage {
		value result = Object({"class" -> type(message).declaration.name});
		result.putAll(message.toJson());
		return result;
	}
	
	registerParser(parsePlayerLoginMessage);
	registerParser(parsePlayerStatisticUpdateMessage);
	registerParser(parsePlayerDetailRequestMessage);
	registerParser(parsePlayerStatisticOutputMessage);
	registerParser(parsePlayerDetailOutputMessage);
	
	registerParser(parseEnterRoomMessage);
	registerParser(parseLeaveRoomMessage);
	registerParser(parseFindMatchTableMessage);
	registerParser(parseFindEmptyTableMessage);
	registerParser(parseRoomStateRequestMessage);
	registerParser(parsePlayerStateRequestMessage);
	registerParser(parseRoomActionResponseMessage);
	registerParser(parseFoundMatchTableMessage);
	registerParser(parseFoundEmptyTableMessage);
	registerParser(parsePlayerListMessageMessage);
	registerParser(parsePlayerStateMessageMessage);
	
	registerParser(parseJoinedTableMessage);
	registerParser(parseLeftTableMessage);
	registerParser(parseCreatedMatchMessage);
	registerParser(parseCreatedMatchMessage);
	registerParser(parseLeaveTableMessage);
	registerParser(parseJoinTableMessage);
	registerParser(parseTableStateRequestMessage);
	registerParser(parseTableStateResponseMessage);
	
	registerParser(parseAcceptedMatchMessage);
	registerParser(parseMatchActivityMessage);
	registerParser(parseMatchEndedMessage);
	registerParser(parseAcceptMatchMessage);
	registerParser(parsePingMatchMessage);
	registerParser(parseEndMatchMessage);
	
	registerParser(parseGameTimeoutMessage);
	registerParser(parseNextRollMessage);
	
	registerParser(parseInitialRollMessage);
	registerParser(parsePlayerReadyMessage);
	registerParser(parseStartTurnMessage);
	registerParser(parsePlayedMoveMessage);
	registerParser(parseUndoneMovesMessage);
	registerParser(parseInvalidMoveMessage);
	registerParser(parseTurnTimedOutMessage);
	registerParser(parseDesynchronizedMessage);
	registerParser(parseNotYourTurnMessage);
	registerParser(parseGameStateResponseMessage);
	registerParser(parseGameActionResponseMessage);
	registerParser(parseStartGameMessage);
	registerParser(parsePlayerBeginMessage);
	registerParser(parseMakeMoveMessage);
	registerParser(parseUndoMovesMessage);
	registerParser(parseEndTurnMessage);
	registerParser(parseTakeTurnMessage);
	registerParser(parseEndGameMessage);
	registerParser(parseGameStateRequestMessage);
	
	registerParser(parseNewGameStatisticMessage);
	registerParser(parseScoreBoardResponseMessage);
}