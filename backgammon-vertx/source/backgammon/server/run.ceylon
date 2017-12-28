import ceylon.language.meta.declaration {
	Module,
	Package
}
import ceylon.language.meta.model {
	Class
}
import ceylon.logging {
	addLogWriter,
	Priority,
	debug,
	fatal,
	error,
	warn,
	info,
	trace
}

import io.vertx.ceylon.core {
	Verticle
}
import io.vertx.core.logging {
	LoggerFactory
}

import java.lang {
	System,
	Runtime,
	Thread,
	Runnable
}

import org.apache.logging.log4j {
	LogManager
}

void logWriter(Priority p, Module|Package c, String m, Throwable? e) {
	value logger = LoggerFactory.getLogger(c.qualifiedName);
	switch (p)
	case (fatal) { logger.fatal(m, e); }
	case (error) { logger.error(m, e); }
	case (warn) { logger.warn(m, e); }
	case (info) { logger.info(m, e); }
	case (debug) { logger.debug(m, e); }
	case (trace) { logger.trace(m, e); }
}

void registerShutdownHook(VertxContainer container) {
	value shutdownHook = object satisfies Runnable {
		shared actual void run() {
			container.shutdown();
			LogManager.shutdown(); // TODO this is log4j2 specific
		}
	};
	Runtime.runtime.addShutdownHook(Thread(shutdownHook, "shutdown-thread"));
}

void runVerticles(Module mod, [Class<Verticle,[]>*] verticleClasses) {
	value container = VertxContainer(mod, "resource/application-conf.json");
	if (container.deployVerticles(verticleClasses)) {
		registerShutdownHook(container); 
	} else {
		container.shutdown();
		Runtime.runtime.exit(-1);
	}
}

shared void run() {
	System.setProperty("log4j.configurationFile", "resource/log4j2.properties");
	System.setProperty("vertx.logger-delegate-factory-class-name", "io.vertx.core.logging.Log4j2LogDelegateFactory");
	System.setProperty("org.jboss.logging.provider", "log4j2");
	addLogWriter(logWriter);
	runVerticles(`module`, [`HttpServerVerticle`, `PlayerRosterVerticle`, `GameRoomVerticle`]);
}