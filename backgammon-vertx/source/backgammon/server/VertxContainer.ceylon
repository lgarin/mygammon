import backgammon.server.util {
	JsonFile
}
import ceylon.json {
	JsonObject
}
import ceylon.language.meta.declaration {
	Module
}
import ceylon.language.meta.model {
	Class
}
import ceylon.logging {
	logger
}
import ceylon.time {
	Duration
}

import io.vertx.ceylon.core {
	Verticle,
	DeploymentOptions,
	vertxFactory=vertx
}
import java.util.concurrent {
	TimeUnit,
	CountDownLatch
}
import java.util.concurrent.atomic {
	AtomicInteger
}

final class VertxContainer(Module mod, String configFile, Duration startupShutdownTimeout = Duration(30 * 1000)) {
	value log = logger(mod);
	value container = vertxFactory.vertx();
	
	function parseConfiguration() {
		value file = JsonFile(configFile);
		if (is JsonObject result = file.readContent()) {
			return result;
		} else {
			return null;
		}
	}
	
	
	function waitLatch(CountDownLatch latch) {
		try {
			return latch.await(startupShutdownTimeout.milliseconds, TimeUnit.\iMILLISECONDS);
		} catch (Exception e) {
			return false;
		}
	}
	
	shared void shutdown() {
		log.info("Shutting down...");
		value latch = CountDownLatch(1);
		container.close((Throwable? e) => latch.countDown());
		if (waitLatch(latch)) {
			log.info("Shutdown completed");
		} else {
			log.info("Shutdown timed out");
		}
	}
	
	shared Boolean deployVerticles([Class<Verticle,[]>*] verticleClasses) {
		log.info("Deploying version ``mod.version``...");
		value options = DeploymentOptions { config = parseConfiguration();  };
		value latch = CountDownLatch(verticleClasses.size);
		value successCount = AtomicInteger(0);
		for (verticleClass in verticleClasses) {
			verticleClass().deploy(container, options, (String|Throwable ar) {
				if (is Throwable ar) {
					log.error("Failed to deploy ``verticleClass.declaration.name``", ar);
				} else {
					successCount.incrementAndGet();
				}
				latch.countDown();
			});
		}
		waitLatch(latch);
		if (successCount.intValue() == verticleClasses.size) {
			log.info("Startup completed");
			return true;
		} else {
			log.fatal("Startup failed");
			return false;
		}
	}
}