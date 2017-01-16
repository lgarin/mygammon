import ceylon.test {

	test,
	afterTest
}
import backgammon.server.util {

	JsonFile
}
import ceylon.json {
	Object,
	Array
}
import ceylon.file {

	current,
	File
}
class JsonFileTest() {
	value path = "test.json";
	value file = JsonFile(path);
	
	afterTest
	shared void deleteFile() {
		if (is File file = current.childPath(path).resource) {
			file.delete();
		}
	}
	
	test
	shared void writeNonEmptyFile() {
		file.writeArray({Object {"name1" -> "value1"}, Object {"name2" -> "value2"}});
		value result = file.readContent();
		assert (is Array result);
		assert (result.size == 2);
	}
	
	test
	shared void writeEmptyFile() {
		file.writeArray({});
		value result = file.readContent();
		assert (is Array result);
		assert (result.size == 0);
	}
}