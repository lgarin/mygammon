package backgammon.keycloak.test;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;

import org.assertj.core.api.Assertions;
import org.junit.Test;

import backgammon.keycloak.BirthdateCheck;

public class BirthdateCheckTest extends Assertions {

	BirthdateCheck check = new BirthdateCheck();
	
	@Test
	public void checkMimimumAge() {
		assertThat(check.hasMinimumAge("1.12.2010", 1)).isTrue();
		assertThat(check.hasMinimumAge("1-12-2010", 1)).isTrue();
		assertThat(check.hasMinimumAge("12/1/2010", 1)).isTrue();
		assertThat(check.hasMinimumAge("1-2-2010", 1)).isTrue();
		assertThat(check.hasMinimumAge("1.2.2010", 1)).isTrue();
		assertThat(check.hasMinimumAge("2/1/2010", 1)).isTrue();
		assertThat(check.hasMinimumAge("01.2.2010", 100)).isFalse();
		assertThat(check.hasMinimumAge("01-2-2010", 100)).isFalse();
		assertThat(check.hasMinimumAge("2/01/2010", 100)).isFalse();
		assertThat(check.hasMinimumAge("02/29/2012", 100)).isFalse();
		assertThat(check.hasMinimumAge(LocalDate.now().plusYears(-10).toString(), 10)).isTrue();
	}
	
	@Test
	public void checkInvalidFormat() {
		assertThatExceptionOfType(DateTimeParseException.class).isThrownBy(() -> check.hasMinimumAge("13/2/2010", 1));
		assertThatExceptionOfType(DateTimeParseException.class).isThrownBy(() -> check.hasMinimumAge("2.13.2010", 1));
		assertThatExceptionOfType(DateTimeParseException.class).isThrownBy(() -> check.hasMinimumAge("2/01.2010", 1));
		assertThatExceptionOfType(DateTimeParseException.class).isThrownBy(() -> check.hasMinimumAge("29-02-2010", 1));
		assertThatExceptionOfType(DateTimeParseException.class).isThrownBy(() -> check.hasMinimumAge("30.2.2012", 1));
		assertThatExceptionOfType(DateTimeParseException.class).isThrownBy(() -> check.hasMinimumAge("31.04.2010", 1));
		assertThatExceptionOfType(DateTimeParseException.class).isThrownBy(() -> check.hasMinimumAge("30 04 2010", 1));
	}
	
	@Test
	public void checkReformat() {
		assertThat(check.reformat("02/29/2012")).isEqualTo("2012-02-29");
		assertThat(check.reformat("03/02/2012")).isEqualTo("2012-03-02");
		assertThat(check.reformat("3/2/2012")).isEqualTo("2012-03-02");
		assertThat(check.reformat("2-3-2012")).isEqualTo("2012-03-02");
		assertThat(check.reformat("22.3.2012")).isEqualTo("2012-03-22");
	}
}
