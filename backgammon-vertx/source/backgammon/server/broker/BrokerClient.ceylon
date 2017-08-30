import backgammon.server.util {
	ObtainableLock
}

import ceylon.json {
	Object,
	parse
}
import ceylon.logging {
	logger
}

import java.util.concurrent {
	Executors
}

import org.apache.activemq.artemis.api.core {
	SimpleString
}
import org.apache.activemq.artemis.api.core.client {
	ActiveMQClient,
	ClientMessage,
	ClientSession
}

import backgammon.server {
	ServerConfiguration
}
import java.util.concurrent.atomic {

	AtomicInteger
}
import java.lang {

	Runnable,
	Thread
}

shared final class BrokerClient(ServerConfiguration config) satisfies Destroyable  {
	value serverLocator = ActiveMQClient.createServerLocator(config.brokerUrl);
	
	value threadCounter = AtomicInteger();
	 
	function threadFactory(Runnable runnable) {
	 return Thread(runnable, "broker-client-``threadCounter.incrementAndGet()``");
	}
	 
	serverLocator.setThreadPools(Executors.newSingleThreadExecutor(threadFactory), Executors.newSingleThreadScheduledExecutor(threadFactory));
	
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
	value lock = ObtainableLock(); 
	value producer = session.createProducer(SimpleString(queueName));
	
	shared void send(Object json) {
		try (lock) {
			value queueMessage = session.createMessage(true);
			queueMessage.bodyBuffer.writeString(json.string);
			producer.send(queueMessage);
		}
	}
	
	shared actual void destroy(Throwable? error) {
		session.close();
	}
}

shared final class BrokerConsumer(ClientSession session, String queueName, void consume(Object json)) satisfies Destroyable  {
	value lock = ObtainableLock(); 
	value consumer = session.createConsumer(SimpleString(queueName));
	
	void handleMessage(ClientMessage message) {
		try (lock) {
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