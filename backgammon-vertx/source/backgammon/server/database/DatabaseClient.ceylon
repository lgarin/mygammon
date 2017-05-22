
import backgammon.server {
	ServerConfiguration
}

import ceylon.interop.java {
	javaString,
	CeylonMap,
	CeylonStringMap
}

import java.lang {
	JString=String
}
import java.util {
	HashMap
}

import org.neo4j.driver.v1 {
	GraphDatabase,
	AuthTokens,
	AccessMode,
	Transaction
}

shared class DatabaseTransaction(Transaction transaction) satisfies Destroyable {
	
	value map = HashMap<JString, Object>();
	
	shared actual void destroy(Throwable? error) {
		transaction.close();
	}
	
	shared void execute(String command, <String->Object>* parameters)(void process(Map<String,Object> result)) {
		map.clear();
		for (value entry in parameters) {
			map.put(javaString(entry.key), entry.item);
		}
		try {
			value result = transaction.run(command, map);
			while (result.hasNext()) {
				process(CeylonStringMap(CeylonMap(result.next().asMap())));
			}
			
		} catch (Exception e) {
			transaction.failure();
			throw e;
		}
	}
}

shared class DatabaseClient(ServerConfiguration config, Boolean readOnly = true) satisfies Destroyable  {
	value driver = GraphDatabase.driver(config.neo4jUrl, AuthTokens.basic(config.neo4jUser, config.neo4jPass));
	value session = driver.session(readOnly then AccessMode.read else AccessMode.write);

	shared DatabaseTransaction beginTx() {
		return DatabaseTransaction(session.beginTransaction());
	}
	
	shared actual void destroy(Throwable? error) {
		session.close();
	}
}

