import backgammon.client.browser {

	Event,
	window,
	newXMLHttpRequest
}
import ceylon.time {

	now
}
import backgammon.shared {

	PlayerInfo,
	parseBase64PlayerInfo
}
import ceylon.regex {

	regex
}
import ceylon.json {

	Object,
	parse
}
abstract shared class BasePage() {
	
	variable PlayerInfo? playerInfo = null;
	shared formal Boolean handleServerMessage(String typeName, Object json);
	
	shared void onServerMessage(String messageString) {
		print(messageString);
		if (is Object json = parse(messageString), exists typeName = json.keys.first) {
			if (!handleServerMessage(typeName, json.getObject(typeName))) {
				onServerError("Cannot handle message: ``json.pretty``");
			}
		} else {
			onServerError("Cannot parse server response: ``messageString``");
		}
	}
	
	shared void onServerError(String messageString) {
		print(messageString);
		window.alert("An unexpected error occured.\r\nThe page will be reloaded.\r\n\r\nTimestamp:``now()``\r\nDetail:\r\n``messageString``");
		window.location.reload();
	}
	
	shared void makeApiRequest(String url) {
		value request = newXMLHttpRequest();	
		request.open("GET", url, true);
		request.send();
		request.onload = void (Event event) {
			if (request.status == 200) {
				onServerMessage(request.responseText);
			} else if (request.status == 401) {
				window.location.\iassign("/start");
			} else {
				onServerError(request.statusText);
			}
		};
	}
	
	function extractEncodedPlayerInfo() {
		value match = regex("playerInfo=([^\\;\\s]+)").find(window.document.cookie);
		if (exists match) {
			return match.groups[0];
		}
		return null;
	}
	
	shared PlayerInfo? extractPlayerInfo() {
		if (!playerInfo exists) {
			if (exists encodedInfo = extractEncodedPlayerInfo()) {
				playerInfo = parseBase64PlayerInfo(encodedInfo);
			}
		}
		return playerInfo;
	}
}