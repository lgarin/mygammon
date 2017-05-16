native("jvm")
module backgammon.server "2.0.0" {
	shared import java.base "8";
	shared import maven:"org.apache.logging.log4j:log4j-api" "2.6.2";
	import maven:"org.apache.logging.log4j:log4j-core" "2.6.2";
	import maven:"org.apache.activemq:artemis-server" "2.0.0";
	import maven:"org.apache.activemq:artemis-commons" "2.0.0";
	import maven:"org.apache.activemq:artemis-core-client" "2.0.0";
	import maven:"org.neo4j:neo4j-common" "3.2.0";
	import maven:"org.neo4j:neo4j-kernel" "3.2.0";
	import maven:"org.neo4j:neo4j-bolt" "3.2.0";
	import maven:"org.neo4j:neo4j-unsafe" "3.2.0";
	import maven:"org.neo4j:neo4j-collections" "3.2.0";
	import maven:"org.neo4j:neo4j-primitive-collections" "3.2.0";
	import maven:"org.neo4j:neo4j-logging" "3.2.0";
	import maven:"org.neo4j:neo4j-io" "3.2.0";
	import maven:"org.neo4j:neo4j-resource" "3.2.0";
	import maven:"org.neo4j:neo4j-configuration" "3.2.0";
	import maven:"org.neo4j:neo4j-index" "3.2.0";
	import maven:"org.neo4j:neo4j-graphdb-api" "3.2.0";
	import ceylon.interop.java "1.3.2";
	import io.vertx.ceylon.web "3.4.1";
	import io.vertx.ceylon.auth.oauth2 "3.4.1";
	import ceylon.file "1.3.2";
	import ceylon.logging "1.3.2";
	shared import backgammon.shared "2.0.0";
}
