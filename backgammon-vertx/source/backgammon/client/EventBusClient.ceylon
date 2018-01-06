shared class EventBusClient(void onMessage(String message), void onError(String error)) {
	variable dynamic eventBus = null;
	variable [String*] addressList = [];
	
	void messageCallback(dynamic error, dynamic message) {
		dynamic {
			if (exists error) {
				onError(JSON.stringify(error));
			} else {
				onMessage(JSON.stringify(message.body));
			}
		}
	}
	
	dynamic {
		dynamic bus = EventBus("/eventbus/");
		bus.onopen = void() {
			for (address in addressList) {
				bus.registerHandler(address, messageCallback);
			}
			eventBus = bus;
		};
		
		bus.onerror = void(dynamic error) {
			if (exists error, exists reason = error.reason, reason != "") {
				onError(error.reason);
			}
		};
		
		bus.onclose = void(dynamic error) {
			eventBus = null;
			if (exists error, exists reason = error.reason, reason != "") {
				onError(error.reason);
			}
		};
	}
	
	shared void addAddress(String address) {
		addressList = [address, *addressList];
		dynamic {
			if (exists bus = eventBus, bus.state == EventBus.OPEN) {
				bus.registerHandler(address, messageCallback);
			}
		}
	}
	
	shared void removeAddresses(Boolean selecting(String element)) {
		dynamic {
			if (exists bus = eventBus, bus.state == EventBus.OPEN) {
				for (address in addressList.select(selecting)) {
					bus.unregisterHandler(address, messageCallback);
				}
			}
		}
		addressList = addressList.select(selecting);
	}
	
	shared void close() {
		dynamic {
			if (exists bus = eventBus, bus.state == EventBus.OPEN) {
				bus.close();
			}
		}
	}
}