class EventBusClient(String address, void onMessage(String message), void onError(String error)) {
	dynamic eventBus;
	
	dynamic {
		eventBus = EventBus("/eventbus/");
		eventBus.onopen = void() {
			eventBus.registerHandler(address, (dynamic error, dynamic message) {
				if (exists error) {
					onError(JSON.stringify(error));
				} else {
					onMessage(JSON.stringify(message.body));
				}
			});
		};
	}
	
	shared void close() {
		dynamic {
			if (eventBus.state == EventBus.OPEN) {
				eventBus.close();
			}
		}
	}
}