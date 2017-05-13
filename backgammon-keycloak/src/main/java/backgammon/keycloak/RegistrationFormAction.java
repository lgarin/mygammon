package backgammon.keycloak;

import java.util.ArrayList;
import java.util.List;

import javax.ws.rs.core.MultivaluedMap;

import org.keycloak.authentication.FormAction;
import org.keycloak.authentication.FormContext;
import org.keycloak.authentication.ValidationContext;
import org.keycloak.authentication.forms.RegistrationPage;
import org.keycloak.events.Details;
import org.keycloak.events.Errors;
import org.keycloak.forms.login.LoginFormsProvider;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.models.utils.FormMessage;
import org.keycloak.services.messages.Messages;
import org.keycloak.services.validation.Validation;

public class RegistrationFormAction implements FormAction {

	public static final String FIELD_BIRTHDATE = "birthdate";
	public static final String MISSING_BIRTHDATE = "missingBirthdateMessage";
	
	public void close() {
		
	}

	public void buildPage(FormContext context, LoginFormsProvider form) {
		
	}

	public void validate(ValidationContext context) {
		MultivaluedMap<String, String> formData = context.getHttpRequest().getDecodedFormParameters();
        List<FormMessage> errors = new ArrayList<>();

        context.getEvent().detail(Details.REGISTER_METHOD, "form");

        if (Validation.isBlank(formData.getFirst((FIELD_BIRTHDATE)))) {
            errors.add(new FormMessage(FIELD_BIRTHDATE, MISSING_BIRTHDATE));
        }
        
        if (Validation.isBlank(formData.getFirst(Validation.FIELD_EMAIL))) {
            errors.add(new FormMessage(RegistrationPage.FIELD_EMAIL, Messages.MISSING_EMAIL));
        }
        
        if (errors.size() > 0) {
            context.error(Errors.INVALID_REGISTRATION);
            context.validationError(formData, errors);
        } else {
            context.success();
        }
	}

	public void success(FormContext context) {
		UserModel user = context.getUser();
        MultivaluedMap<String, String> formData = context.getHttpRequest().getDecodedFormParameters();
        user.setSingleAttribute(FIELD_BIRTHDATE, formData.getFirst(FIELD_BIRTHDATE));
	}

	public boolean requiresUser() {
		return false;
	}

	public boolean configuredFor(KeycloakSession session, RealmModel realm, UserModel user) {
		return true;
	}

	public void setRequiredActions(KeycloakSession session, RealmModel realm, UserModel user) {
		
	}

}
