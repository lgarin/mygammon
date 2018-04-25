
shared dynamic Window {
    
    //shared formal WindowProxy window;
    //shared formal WindowProxy self;
    //shared formal Document document;
    shared formal variable String name;
    shared formal Location location;
    //shared formal History history;
    
    shared formal BarProp locationbar;
    shared formal BarProp menubar;
    shared formal BarProp personalbar;
    shared formal BarProp scrollbars;
    shared formal BarProp statusbar;
    shared formal BarProp toolbar;
    shared formal variable String status;
    //shared formal void close();
    //shared formal Boolean? closed;
    //shared formal void stop();
    //shared formal void focus();
    //shared formal void blur();
    //shared formal WindowProxy frames;
    //shared formal Integer length;
    //shared formal WindowProxy top;
    //shared formal WindowProxy? opener;
    //shared formal WindowProxy parent;
    //shared formal Element? frameElement;
    //shared formal WindowProxy open(String url = "about:blank", String target = "_blank", String features = "", Boolean replace = false);
    
    //shared formal Navigator navigator;
    //shared formal External? external;
    //shared formal ApplicationCache applicationCache;
    shared formal void alert(String message = "");
    shared formal Boolean confirm(String message = "");
    shared formal String? prompt(String message = "", String default = "");
    //shared formal void print();
}

shared dynamic Location {
	"Navigates to the given page."
	shared formal void \iassign(String url);
	
	"Removes the current page from the session history and navigates to
	 the given page."
	shared formal void replace(String url);
	
	"Reloads the current page."
	shared formal void reload();
	
	shared formal String href;
}

shared dynamic BarProp {
	shared formal variable Boolean visible;
}

shared Window window {
	dynamic {
		return eval("window");
	}
}