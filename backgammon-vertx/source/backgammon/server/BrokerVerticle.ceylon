import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	Verticle
}

import org.apache.activemq.artemis.core.server.embedded {
	EmbeddedActiveMQ
}

final class BrokerVerticle() extends Verticle() {
	value log = logger(`package`);
	
	value embedded = EmbeddedActiveMQ();
	
	shared actual void start() {
		if (exists brokerConfig = `module`.resourceByPath("broker.xml")) {
			log.debug("Broker config URI ``brokerConfig.uri``");
			embedded.setConfigResourcePath(brokerConfig.uri);
			embedded.start();
			log.info("Started broker : ``embedded.activeMQServer.nodeID``");
		} else {
			throw Exception("Cannot find broker.xml configuration");
		}
	}
	
	shared actual void stop() {
		embedded.stop();
		log.info("Stopped broker");
	}
}