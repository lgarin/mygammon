suppressWarnings("missingImportPrefix")
native("jvm")
module backgammon.server "1.2.1" {
	shared import java.base "8";
	shared import "org.apache.logging.log4j:log4j-api" "2.6.2";
	import "org.apache.logging.log4j:log4j-core" "2.6.2";
	import io.vertx.ceylon.web "3.3.2";
	import io.vertx.ceylon.auth.oauth2 "3.3.2";
	import ceylon.file "1.2.2";
	import ceylon.logging "1.2.2";
	shared import backgammon.shared "1.2.1";
}
