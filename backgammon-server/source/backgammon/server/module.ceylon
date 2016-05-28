native("jvm")
module backgammon.server "1.0.0" {
	shared import java.base "8";
	shared import io.vertx.ceylon.web "3.2.2";
	shared import io.vertx.ceylon.auth.shiro "3.2.2";
	shared import ceylon.logging "1.2.2";
	shared import "log4j:log4j" "1.2.17";
}
