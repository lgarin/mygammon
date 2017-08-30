native("jvm")
module backgammon.server "2.0.0" {
	shared import java.base "8";
	shared import maven:"org.apache.logging.log4j:log4j-api" "2.8.2";
	shared import maven:"org.apache.logging.log4j:log4j-core" "2.8.2";
	import maven:"org.apache.activemq:artemis-commons" "2.0.0";
	import maven:"org.apache.activemq:artemis-core-client" "2.0.0";
	import maven:"org.neo4j.driver:neo4j-java-driver" "1.3.0";
	import ceylon.interop.java "1.3.3";
	import io.vertx.ceylon.web "3.4.2";
	import maven:"io.vertx:vertx-jwt" "3.4.2";
	import io.vertx.ceylon.auth.oauth2 "3.4.2";
	import ceylon.file "1.3.3";
	import ceylon.logging "1.3.3";
	shared import backgammon.shared "2.0.0";
}
