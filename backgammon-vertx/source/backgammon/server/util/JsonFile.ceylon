import ceylon.file {

	current,
	File,
	lines,
	Writer,
	Nil
}
import ceylon.json {

	Object,
	parse,
	Array
}
final shared class JsonFile(String filepath) {
	function readWholeFile(String path) {
		if (is File configFile = current.childPath(path).resource) {
			return lines(configFile).reduce((String partial, String element) => partial + element);
		} else {
			return null;
		}
	}
	
	shared String|Boolean|Integer|Float|Object|Array|Null readContent() {
		if (exists fileContent = readWholeFile(filepath)) {
			return parse(fileContent);
		} else {
			return null;
		}
	}
	
	function createWriter(String filepath) {
		switch (file = current.childPath(filepath).resource)
		case (is File) {
			return file.Overwriter();
		}
		case (is Nil) {
			return file.createFile().Overwriter();
		}
		else {
			throw Exception("Path ``filepath`` does not denote a file");
		}
	}
	
	void writeJsonArray(Writer writer, {Object*} items) {
		writer.writeLine("[");
		variable Boolean first = true;
		for (item in items) {
			if (!first) {
				writer.writeLine(",");
			}
			writer.write(item.string);
			first = false;
		}
		writer.writeLine("]");
	}
	
	shared void writeArray({Object*} items) {
		// TODO use try with resources
		value writer = createWriter(filepath);
		try {
			writeJsonArray(writer, items);
		} finally {
			writer.close();
		}
	}
}