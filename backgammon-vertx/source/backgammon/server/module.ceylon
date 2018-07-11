native("jvm")
module backgammon.server "2.1.1" {
	shared import java.base "8";
	shared import maven:"org.apache.logging.log4j:log4j-api" "2.8.2";
	import maven:"io.vertx:vertx-core" "3.5.0";
	import maven:"io.vertx:vertx-web" "3.5.0";
	import maven:"io.vertx:vertx-jwt" "3.5.0";
	import maven:"io.vertx:vertx-auth-common" "3.5.0";
	import maven:"io.vertx:vertx-auth-oauth2" "3.5.0";
	import ceylon.file "1.3.3";
	import ceylon.logging "1.3.3";
	import ceylon.interop.java "1.3.3";
	import io.vertx.ceylon.web "3.5.0.Beta1";
	import io.vertx.ceylon.auth.common "3.5.0.Beta1";
	import io.vertx.ceylon.auth.oauth2 "3.5.0.Beta1";
	shared import backgammon.shared "2.1.1";
}