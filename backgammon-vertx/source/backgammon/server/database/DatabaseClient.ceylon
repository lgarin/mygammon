
import backgammon.server {
	ServerConfiguration
}

import ceylon.interop.java {
	javaString
}
import ceylon.json {
	JsonObject=Object,
	JsonValue=Value,
	JsonArray=Array
}

import java.lang {
	JString=String
}
import java.util {
	JHashMap=HashMap
}

import org.neo4j.driver.v1 {
	GraphDatabase,
	AuthTokens,
	AccessMode,
	Transaction,
	Record,
	Value
}


shared class DatabaseTransaction(Transaction transaction) satisfies Destroyable {
	
	value map = JHashMap<JString, Object>();
	
	shared actual void destroy(Throwable? error) {
		transaction.close();
	}
	
	JHashMap<JString, Object?> toJavaMap(JsonObject obj) {
		value map = JHashMap<JString, Object?>();
		for (key->item in obj) {
			map.put(javaString(key), toJavaObject(item));
		}
		return map;
	}
	
	Object? toJavaObject(JsonValue obj) {
		switch (obj) 
		case (is JsonObject) {
			return toJavaMap(obj);
		}
		case (is JsonArray) {
			return [for (v in obj) toJavaObject(v)];
		}
		else {
			return obj;
		}
	}
	
	JsonValue toJsonValue(Value val) {
		value typeSystem = transaction.typeSystem();
		if (val.hasType(typeSystem.null())) {
			return null;
		} else if (val.hasType(typeSystem.string())) {
			return val.asString();
		} else if (val.hasType(typeSystem.integer())) {
			return val.asInt();
		} else if (val.hasType(typeSystem.boolean())) {
			return val.asBoolean();
		} else if (val.hasType(typeSystem.list())) {
			return JsonArray { for (item in val.asList(toJsonValue)) item};
		} else {
			return JsonObject { for (entry in val.asMap(toJsonValue).entrySet()) entry.key.string->entry.\ivalue };
		}
	}
	
	JsonObject mapRecord(Record rec) => JsonObject { for (key in rec.keys()) key.string->toJsonValue(rec.get(key.string)) };
	
	shared void execute(String command, <String->JsonValue>* parameters)(void process(JsonObject result)) {
		map.clear();
		for (value entry in parameters) {
			map.put(javaString(entry.key), toJavaObject(entry.item));
		}
		value result = transaction.run(command, map);
		while (result.hasNext()) {
			process(mapRecord(result.next()));
		}
	}
	
	shared void success() {
		transaction.success();
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

