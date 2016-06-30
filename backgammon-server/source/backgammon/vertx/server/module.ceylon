native("jvm")
module backgammon.vertx.server "1.0.0" {
	shared import java.base "8";
	shared import io.vertx.ceylon.web "3.3.0";
	shared import io.vertx.ceylon.auth.oauth2 "3.3.0";
	shared import ceylon.logging "1.2.2";
	shared import ceylon.json "1.2.2";
	shared import "log4j:log4j" "1.2.17";
	import backgammon.server.match "1.0.0";
}
