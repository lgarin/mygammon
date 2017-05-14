package backgammon.keycloak;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;

public class BirthdateCheck {

	private DateTimeFormatter dateFormatter = new DateTimeFormatterBuilder()
			  .appendPattern("[uuuu-MM-dd]")
			  .appendPattern("[M/d/uuuu]")
			  .appendPattern("[d-M-uuuu]")
			  .appendPattern("[d.M.uuuu]")
			  .appendPattern("[MM/dd/uuuu]")
			  .appendPattern("[dd-MM-uuuu]")
			  .appendPattern("[dd.MM.uuuu]")
			  .appendPattern("[M/dd/uuuu]")
			  .appendPattern("[dd-M-uuuu]")
			  .appendPattern("[dd.M.uuuu]")
			  .appendPattern("[MM/d/uuuu]")
			  .appendPattern("[d-MM-uuuu]")
			  .appendPattern("[d.MM.uuuu]")
			  .toFormatter()
			  .withResolverStyle(ResolverStyle.STRICT);
	
	public String reformat(String date) {
		try {
        	return LocalDate.parse(date, dateFormatter).format(DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (DateTimeParseException e) {
        	return null;
        }
	}
	
	public boolean hasMinimumAge(String date, int minimumAge) throws DateTimeParseException {
		return !LocalDate.parse(date, dateFormatter).plusYears(minimumAge).isAfter(LocalDate.now());
	}
}
