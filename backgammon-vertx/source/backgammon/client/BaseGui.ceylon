import backgammon.client.browser {

	Element,
	Document
}

shared abstract class BaseGui {
	
	shared static String hiddenClass = "hidden";
	
	Document document;
	
	shared new(Document document) {
		this.document = document;
	}
	
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
	
	shared Boolean isDropDownVisible(String elementId) {
		if (exists element = document.getElementById(elementId)) {
			return element.classList.contains("open");
		} else {
			return false;
		}
	}
	
	shared Boolean toggleDropDown(String elementId) {
		if (exists element = document.getElementById(elementId)) {
			if (element.classList.contains("open")) {
				element.classList.remove("open");
				return false;
			} else {
				element.classList.add("open");
				return true;
			}
		} else {
			return false;
		}
	}
	
	shared String? readElementValue(String elementId) {
		dynamic {
			return jQuery("#``elementId``").val();
		}
	}
	
	shared void writeElementValue(String elementId, String elementValue) {
		dynamic {
			jQuery("#``elementId``").val(elementValue);
		}
	}
	
	shared void showDialog(String dialogName, {<String->String>*} variableMap = {}) {
		replaceVariables(variableMap);
		dynamic {
			jQuery("#``dialogName``").dialog("open");
		}
	}
	
	shared void hideDialog(String dialogName) {
		dynamic {
			jQuery("#``dialogName``").dialog("close");
		}
	}
	
	shared void hideAllDialogs() {
		dynamic {
			jQuery(".ui-dialog-content").dialog("close");
		}
	}
	
	shared void replaceVariables({<String->String>*} variableMap) {
		dynamic {
			for (value variableEntry in variableMap) {
				jQuery("#``variableEntry.key``").html(variableEntry.item);
			}
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