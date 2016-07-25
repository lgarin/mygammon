native("jvm")
module backgammon.vertx.server "1.0.0" {
	shared import java.base "8";
	shared import io.vertx.ceylon.web "3.3.2";
	import io.vertx.ceylon.auth.oauth2 "3.3.2";
	import ceylon.json "1.2.2";
	import ceylon.file "1.2.2";
	import ceylon.logging "1.2.2";
	shared import "log4j:log4j" "1.2.17";
	import backgammon.server.match "1.0.0";
	import backgammon.server.game "1.0.0";
}