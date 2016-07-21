final class EventBusClient() {
	variable Boolean initialized = false;
	
	dynamic eventBus;
	dynamic {
		eventBus = EventBus("/eventbus/");
	}
	
	shared void registerHandler(String address, Anything process(String? message, String? error)) {
		if (initialized) {
			dynamic {
				eventBus.registerHandler(address, (dynamic error, dynamic message) {
					process(JSON.stringify(message), JSON.stringify(error));
				});
			}
		} else {
			dynamic {
				eventBus.onopen = void() {
					initialized = true;
					eventBus.registerHandler(address, (dynamic error, dynamic message) {
						process(JSON.stringify(message), JSON.stringify(error));
					});
				};
			}
		}
	}
}