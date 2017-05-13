import ceylon.logging {
	logger
}

import io.vertx.ceylon.core {
	Verticle
}

import org.apache.activemq.artemis.core.server.embedded {
	EmbeddedActiveMQ
}
import backgammon.server.broker {

	BrokerClient
}

import ceylon.json { Object }

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
		value client = BrokerClient();
		value sender = client.createSender("queue1");
		vertx.setPeriodic(1000, (Integer a) => sender.send(Object({"test" -> "Test"})));
		client.createConsumer("queue1", (Object json) => log.info(json.string));
	}
	
	shared actual void stop() {
		embedded.stop();
		log.info("Stopped broker");
	}
}