package backgammon.keycloak;

import java.util.List;

import org.keycloak.Config.Scope;
import org.keycloak.authentication.FormAction;
import org.keycloak.authentication.FormActionFactory;
import org.keycloak.models.AuthenticationExecutionModel.Requirement;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.provider.ProviderConfigProperty;

public class RegistrationFormActionFactory implements FormActionFactory {

    public static final String PROVIDER_ID = "registration-mygammon-action";

    
    public FormAction create(KeycloakSession session) {
        return new RegistrationFormAction();
    }

    public String getDisplayType() {
        return "MyGammon Profile Validation";
    }

	public void init(Scope config) {
		System.out.println("init MyGammon Action " + config.toString());
	}

	public void postInit(KeycloakSessionFactory factory) {
	}

	public void close() {
	}

	public String getId() {
		return PROVIDER_ID;
	}

	public String getReferenceCategory() {
		return null;
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
		return "Test";
	}

	public List<ProviderConfigProperty> getConfigProperties() {
		return null;
	}
}
