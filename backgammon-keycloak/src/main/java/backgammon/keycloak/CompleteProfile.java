package backgammon.keycloak;

import java.time.format.DateTimeParseException;
import java.util.List;

import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.Response;

import org.keycloak.Config;
import org.keycloak.authentication.RequiredActionContext;
import org.keycloak.authentication.RequiredActionFactory;
import org.keycloak.authentication.RequiredActionProvider;
import org.keycloak.events.Details;
import org.keycloak.events.EventBuilder;
import org.keycloak.events.EventType;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.models.utils.FormMessage;
import org.keycloak.services.messages.Messages;
import org.keycloak.services.resources.AttributeFormDataProcessor;
import org.keycloak.services.validation.Validation;

public class CompleteProfile implements RequiredActionProvider, RequiredActionFactory {
	
	public static final String FIELD_BIRTHDATE = "birthdate";
	public static final String MISSING_BIRTHDATE = "missingBirthdateMessage";
	public static final String INVALID_BIRTHDATE = "invalidBirthdateMessage";
	public static final String AGE_REQUIEREMENT = "minimumAgeMessage";
	
	public static final int MINIMUM_AGE = 18;
	
	private BirthdateCheck birthdateCheck = new BirthdateCheck();
	
    @Override
    public void evaluateTriggers(RequiredActionContext context) {
    }

    @Override
    public void requiredActionChallenge(RequiredActionContext context) {
        Response challenge = context.form()
                .createResponse(UserModel.RequiredAction.UPDATE_PROFILE);
        context.challenge(challenge);
    }

    @Override
    public void processAction(RequiredActionContext context) {
        EventBuilder event = context.getEvent();
        event.event(EventType.UPDATE_PROFILE);
        MultivaluedMap<String, String> formData = context.getHttpRequest().getDecodedFormParameters();
        UserModel user = context.getUser();
        KeycloakSession session = context.getSession();
        RealmModel realm = context.getRealm();


        List<FormMessage> errors = Validation.validateUpdateProfileForm(realm, formData);
        
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
        
        if (errors != null && !errors.isEmpty()) {
            Response challenge = context.form()
                    .setErrors(errors)
                    .setFormData(formData)
                    .createResponse(UserModel.RequiredAction.UPDATE_PROFILE);
            context.challenge(challenge);
            return;
        }

        if (realm.isEditUsernameAllowed()) {
            String username = formData.getFirst("username");
            String oldUsername = user.getUsername();

            boolean usernameChanged = oldUsername != null ? !oldUsername.equals(username) : username != null;

            if (usernameChanged) {

                if (session.users().getUserByUsername(username, realm) != null) {
                    Response challenge = context.form()
                            .setError(Messages.USERNAME_EXISTS)
                            .setFormData(formData)
                            .createResponse(UserModel.RequiredAction.UPDATE_PROFILE);
                    context.challenge(challenge);
                    return;
                }

                user.setUsername(username);
            }

        }

        user.setFirstName(formData.getFirst("firstName"));
        user.setLastName(formData.getFirst("lastName"));
        user.setSingleAttribute(FIELD_BIRTHDATE, birthdateCheck.reformat(formData.getFirst(FIELD_BIRTHDATE)));

        String email = formData.getFirst("email");

        String oldEmail = user.getEmail();
        boolean emailChanged = oldEmail != null ? !oldEmail.equals(email) : email != null;

        if (emailChanged) {
            if (!realm.isDuplicateEmailsAllowed()) {
                UserModel userByEmail = session.users().getUserByEmail(email, realm);

                // check for duplicated email
                if (userByEmail != null && !userByEmail.getId().equals(user.getId())) {
                    Response challenge = context.form()
                            .setError(Messages.EMAIL_EXISTS)
                            .setFormData(formData)
                            .createResponse(UserModel.RequiredAction.UPDATE_PROFILE);
                    context.challenge(challenge);
                    return;
                }
            }

            user.setEmail(email);
            user.setEmailVerified(false);
        }

        AttributeFormDataProcessor.process(formData, realm, user);

        if (emailChanged) {
            event.clone().event(EventType.UPDATE_EMAIL).detail(Details.PREVIOUS_EMAIL, oldEmail).detail(Details.UPDATED_EMAIL, email).success();
        }
        context.success();

    }


    @Override
    public void close() {

    }

    @Override
    public RequiredActionProvider create(KeycloakSession session) {
        return this;
    }

    @Override
    public void init(Config.Scope config) {

    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {

    }

    @Override
    public String getDisplayText() {
        return "Update Full Profile";
    }


    @Override
    public String getId() {
        //return UserModel.RequiredAction.UPDATE_PROFILE.name();
    	return "UPDATE_FULL_PROFILE";
    }
}

