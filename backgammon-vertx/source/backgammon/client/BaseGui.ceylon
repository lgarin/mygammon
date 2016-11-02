import backgammon.client.browser {

	Element,
	Document
}
shared abstract class BaseGui(Document document) {
	
	shared void resetClass(Element element, String* classNames) {
		value classList = element.classList;
		while (classList.length > 0) {
			if (exists item = classList.item(0)) {
				classList.remove(item);
			}
		}
		for (value className in classNames) {
			classList.add(className);
		}
	}
	
	shared void setClass(String elementId, String* classNames) {
		if (exists element = document.getElementById(elementId)) {
			resetClass(element, *classNames);
		}
	}
	
	shared void addClass(String elementId, String className) {
		document.getElementById(elementId)?.classList?.add(className);
	}
	
	shared void removeClass(String elementId, String className) {
		document.getElementById(elementId)?.classList?.remove(className);
	}
	
	shared void showDialog(String dialogName, {<String->String>*} variableMap = {}) {
		dynamic {
			for (value variableEntry in variableMap) {
				jQuery("#``variableEntry.key``").html(variableEntry.item);
			}
			jQuery("#``dialogName``").dialog("open");
		}
	}
	
	shared String translate(String key) {
		if (key.empty || !key.startsWith("_")) {
			return key;
		}
		dynamic {
			return jQuery("#i18n #``key``").text();
		}
	}
}