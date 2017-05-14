package backgammon.keycloak;

import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

import javax.ws.rs.core.MultivaluedMap;

import org.keycloak.Config.Scope;
import org.keycloak.authentication.FormAction;
import org.keycloak.authentication.FormActionFactory;
import org.keycloak.authentication.FormContext;
import org.keycloak.authentication.ValidationContext;
import org.keycloak.authentication.forms.RegistrationPage;
import org.keycloak.events.Details;
import org.keycloak.events.Errors;
import org.keycloak.forms.login.LoginFormsProvider;
import org.keycloak.models.AuthenticationExecutionModel.Requirement;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.models.utils.FormMessage;
import org.keycloak.provider.ProviderConfigProperty;
import org.keycloak.services.messages.Messages;
import org.keycloak.services.validation.Validation;

public class RegistrationBirthdate implements FormAction, FormActionFactory {
	
	public static final String PROVIDER_ID = "registration-profile-action";
	
	public static final String FIELD_BIRTHDATE = "birthdate";
	public static final String MISSING_BIRTHDATE = "missingBirthdateMessage";
	public static final String INVALID_BIRTHDATE = "invalidBirthdateMessage";
	public static final String AGE_REQUIEREMENT = "minimumAgeMessage";
	
	public static final int MINIMUM_AGE = 18;
	
	private BirthdateCheck birthdateCheck = new BirthdateCheck();
			  
	 public FormAction create(KeycloakSession session) {
	        return this;
	    }

	    public String getDisplayType() {
	        return "Birthdate Validation";
	    }

		public void init(Scope config) {
		}

		public void postInit(KeycloakSessionFactory factory) {
		}

		public String getId() {
			return PROVIDER_ID;
		}

		public String getReferenceCategory() {
			return "Birthdate";
		}

		public boolean isConfigurable() {
			return false;
		}
		
		public Requirement[] getRequirementChoices() {
			return new Requirement[] {
	            Requirement.REQUIRED,
	            Requirement.DISABLED
			};
		}

		public boolean isUserSetupAllowed() {
			return false;
		}

		public String getHelpText() {
			return "Validate birthdate and email";
		}

		public List<ProviderConfigProperty> getConfigProperties() {
			return null;
		}
	
	
	public void close() {
		
	}

	public void buildPage(FormContext context, LoginFormsProvider form) {
		
	}

	public void validate(ValidationContext context) {
		MultivaluedMap<String, String> formData = context.getHttpRequest().getDecodedFormParameters();
        List<FormMessage> errors = new ArrayList<>();

        context.getEvent().detail(Details.REGISTER_METHOD, "form");
      
        if (Validation.isBlank(formData.getFirst(Validation.FIELD_EMAIL))) {
        	errors.add(new FormMessage(RegistrationPage.FIELD_EMAIL, Messages.MISSING_EMAIL));
        }

        if (Validation.isBlank(formData.getFirst((FIELD_BIRTHDATE)))) {
            errors.add(new FormMessage(FIELD_BIRTHDATE, MISSING_BIRTHDATE));
        }
        
        try {
        	if (!birthdateCheck.hasMinimumAge(formData.getFirst(FIELD_BIRTHDATE), MINIMUM_AGE)) {
        		errors.add(new FormMessage(FIELD_BIRTHDATE, AGE_REQUIEREMENT));
        	}
        } catch (DateTimeParseException e) {
        	errors.add(new FormMessage(FIELD_BIRTHDATE, INVALID_BIRTHDATE));
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
        user.setSingleAttribute(FIELD_BIRTHDATE, birthdateCheck.reformat(formData.getFirst(FIELD_BIRTHDATE)));
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
