import ceylon.language.meta.declaration {
	Module,
	Package
}
import ceylon.logging {
	addLogWriter,
	logger,
	Priority,
	debug,
	fatal,
	error,
	warn,
	info,
	trace
}

import io.vertx.ceylon.core {
	vertxFactory=vertx
}
import io.vertx.core.logging {
	LoggerFactory
}

import java.lang {
	System
}

import org.apache.log4j {
	BasicConfigurator
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

void runModuleVerticle(Module mod) {
	value log = logger(mod);
	value container = vertxFactory.vertx();
	log.info("Deploying module...");
	container.deployVerticle("ceylon:``mod.name``/``mod.version``", (String|Throwable ar) {
		if (is String ar) {
			log.info("Deploy success");
		} else {
			log.error("Deploy failure", ar);
		}
	});
}

shared void run() {
	BasicConfigurator.configure();
	addLogWriter(logWriter);
	System.setProperty("vertx.logger-delegate-factory-class-name", "io.vertx.core.logging.Log4jLogDelegateFactory"); 
	runModuleVerticle(`module`);
}