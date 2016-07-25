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
	vertxFactory=vertx,
	DeploymentOptions
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
import ceylon.json {

	Object,
	parse
}
import ceylon.file {

	current,
	File,
	lines
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
	if (is File configFile = current.childPath("resource/application-conf.json").resource) {
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

void runModuleVerticle(Module mod) {
	value log = logger(mod);
	value container = vertxFactory.vertx();
	log.info("Deploying module...");
	value options = DeploymentOptions { config = parseConfiguration();  };
	container.deployVerticle("ceylon:``mod.name``/``mod.version``", options, (String|Throwable ar) {
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