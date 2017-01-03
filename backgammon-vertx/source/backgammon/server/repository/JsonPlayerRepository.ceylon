import backgammon.shared {
	PlayerRepositoryInputMessage,
	PlayerRepositoryOutputMessage
}

import ceylon.file {
	File,
	current,
	lines
}
shared final class JsonPlayerRepository(File file) {
	String? readWholeFile(String path) {
		if (is File configFile = current.childPath(path).resource) {
			return lines(configFile).reduce((String partial, String element) => partial + element);
		} else {
			return null;
		}
	}
	
	shared PlayerRepositoryOutputMessage processInputMessage(PlayerRepositoryInputMessage message) {
		return nothing;
	}
	
	shared void readData() {
		
	}
	
	shared void writeData() {
		
	}
}