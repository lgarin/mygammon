shared class EventBusClient(void onMessage(String message), void onError(String error)) {
	variable dynamic eventBus = null;
	variable dynamic reconnectTimer = null;
	
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
	
	void connectEventBus() {
		dynamic {
			dynamic bus = EventBus("/eventbus/");
			bus.onopen = void() {
				if (exists timer = reconnectTimer) {
					clearInterval(timer);
					reconnectTimer = null;
				}
				for (address in addressList) {
					bus.registerHandler(address, messageCallback);
				}
			};
			
			bus.onerror = void(dynamic error) {
				onError(JSON.stringify(error));
			};
			
			bus.onclose = void(dynamic error) {
				if (exists error, !reconnectTimer exists) {
					reconnectTimer = setInterval(connectEventBus, 1800 + 600 * (Math.random() - 0.5));
				}
			};
			
			eventBus = bus;
		}
	}
	
	connectEventBus();
	
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