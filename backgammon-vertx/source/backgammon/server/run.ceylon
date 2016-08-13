import ceylon.file {
	current,
	File,
	lines
}
import ceylon.json {
	Object,
	parse
}
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
	trace,
	Logger
}

import io.vertx.ceylon.core {
	vertxFactory=vertx,
	DeploymentOptions,
	Vertx
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
import java.util.concurrent {
	TimeUnit,
	CountDownLatch
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

String? readWholeFile(String path) {
	if (is File configFile = current.childPath(path).resource) {
		return lines(configFile).reduce((String partial, String element) => partial + element);
	} else {
		return null;
	}
}

Object? parseConfiguration() {
	if (exists fileContent = readWholeFile("resource/application-conf.json")) {
		if (is Object result = parse(fileContent)) {
			return result;
		} else {
			return null;
		}
	} else {
		return null;
	}
}

void registerShutdownHook(Logger log, Vertx container) {
	value shutdownHook = object satisfies Runnable {
		shared actual void run() {
			log.info("Shutting down...");
			value latch = CountDownLatch(1);
			container.close((Throwable? e) => latch.countDown());
			try {
				if (!latch.await(30, TimeUnit.\iSECONDS)) {
					log.error("Timed out waiting for shutdown");
				} else {
					log.info("Shutdown completed");
				}
			} catch (Exception e) {
				log.error("Shutdown failure", e);
			} finally {
				// TODO this is log4j2 specific
				LogManager.shutdown();
			}
		}
	};
	Runtime.runtime.addShutdownHook(Thread(shutdownHook, "shutdown-thread"));
}

void runModuleVerticle(Module mod) {
	value log = logger(mod);
	value container = vertxFactory.vertx();
	log.info("Deploying version ``mod.version``...");
	value options = DeploymentOptions { config = parseConfiguration();  };
	container.deployVerticle("ceylon:``mod.name``/``mod.version``", options, (String|Throwable ar) {
		if (is String ar) {
			log.info("Deploy success");
		} else {
			log.error("Deploy failure", ar);
		}
	});
	
	registerShutdownHook(log, container);
}

shared void run() {
	System.setProperty("log4j.configurationFile", "resource/log4j2.properties");
	System.setProperty("vertx.logger-delegate-factory-class-name", "io.vertx.core.logging.Log4j2LogDelegateFactory");
	addLogWriter(logWriter);
	runModuleVerticle(`module`);
}