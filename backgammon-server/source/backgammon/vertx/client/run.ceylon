import ceylon.interop.browser.dom {
	document,
	Event
}
import ceylon.interop.browser {
	newXMLHttpRequest
}

"Run the module `backgammon.vertx.client`."
shared void run() {
    print("Hello World for Java Script");
    /*
    value req = newXMLHttpRequest();
    
    req.onload = void (Event evt) {
        if (exists container = document.getElementById("container")) {
            value title = document.createElement("h1");
            title.textContent = "Hello from Ceylon";
            container.appendChild(title);
            
            value content = document.createElement("p");
            content.innerHTML = req.responseText;
            container.appendChild(content);
        }
    };
    
    req.open("GET", "/msg.txt");
    req.send();
    */
    
    dynamic {
        /*
        dynamic sock = SockJS("http://localhost:8080/eventbus");
        sock.onMessage = (void (Anything message) {print(message);});
         */
        

    }
    
}