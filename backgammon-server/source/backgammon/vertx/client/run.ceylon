

"Run the module `backgammon.vertx.client`."
shared void run() {
    print("Hello World for Java Script");

    dynamic {

        dynamic eb = EventBus("/eventbus/");
        eb.onopen = void() {
            eb.registerHandler("msg.to.client", (Object error, Object message) {
                console.log("received a message: " + JSON.stringify(message));
            });
        };
    }
    
}