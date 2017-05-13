import ceylon.interop.java {
	javaClass
}
import ceylon.json {
	Object,
	parse
}

import org.apache.activemq.artemis.api.core {
	TransportConfiguration,
	SimpleString
}
import org.apache.activemq.artemis.api.core.client {
	ActiveMQClient,
	ClientMessage,
	ClientSession
}
import org.apache.activemq.artemis.core.remoting.impl.invm {
	InVMConnectorFactory
}
import ceylon.logging {

	logger
}

shared final class BrokerClient() satisfies Destroyable  {
	value connectorFactoryName = javaClass<InVMConnectorFactory>().canonicalName;
	value serverLocator = ActiveMQClient.createServerLocatorWithoutHA(TransportConfiguration(connectorFactoryName));
	value sessionFactory = serverLocator.createSessionFactory();
	
	shared BrokerSender createSender(String queueName) {
		return BrokerSender(sessionFactory.createSession(), queueName);
	}
	
	shared BrokerConsumer createConsumer(String queueName, void consume(Object json)) {
		return BrokerConsumer(sessionFactory.createSession(), queueName, consume);
	}

	shared actual void destroy(Throwable? error) {
		try {
			sessionFactory.close();
		} finally {
			serverLocator.close();
		}
	}
}

shared final class BrokerSender(ClientSession session, String queueName) satisfies Destroyable  {
	
	value producer = session.createProducer(SimpleString(queueName));
	
	shared void send(Object json) {
		value queueMessage = session.createMessage(true);
		queueMessage.bodyBuffer.writeString(json.string);
		producer.send(queueMessage);
	}
	
	shared actual void destroy(Throwable? error) {
		session.close();
	}
}

shared final class BrokerConsumer(ClientSession session, String queueName, void consume(Object json)) satisfies Destroyable  {
	value consumer = session.createConsumer(SimpleString(queueName));
	
	void handleMessage(ClientMessage message) {
		try {
			value body = message.bodyBuffer.readString();
			if (is Object json = parse(body)) {
				consume(json);
			} else {
				logger(`package`).warn("Cannot parse message : ``message``\n``body``");
			}
			message.acknowledge();
		} catch (Exception e) {
			logger(`package`).error("Failed to handle message: ``message``", e);
		}
	}
	
	consumer.setMessageHandler(handleMessage);
	session.start();
	
	shared actual void destroy(Throwable? error) {
		try {
			session.stop();
		} finally {
			session.close();
		}
	}
}