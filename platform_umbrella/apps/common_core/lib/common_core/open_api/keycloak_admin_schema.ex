defmodule CommonCore.OpenAPI.KeycloakAdminSchema do
  @moduledoc false
  defmodule AuthenticationExecutionExportRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :authenticator, :string
      field :authenticatorConfig, :string
      field :authenticatorFlow, :boolean
      field :flowAlias, :string
      field :priority, :integer
      field :requirement, :string
      field :userSetupAllowed, :boolean
    end
  end

  defmodule AuthenticationFlowRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :alias, :string
      embeds_many :authenticationExecutions, AuthenticationExecutionExportRepresentation
      field :builtIn, :boolean
      field :description, :string
      field :id, :string
      field :providerId, :string
      field :topLevel, :boolean
    end
  end

  defmodule AuthenticatorConfigRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :alias, :string
      field :config, :map
      field :id, :string
    end
  end

  defmodule AuthenticationExecutionInfoRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :alias, :string
      field :authenticationConfig, :string
      field :authenticationFlow, :boolean
      field :configurable, :boolean
      field :description, :string
      field :displayName, :string
      field :flowId, :string
      field :id, :string
      field :index, :integer
      field :level, :integer
      field :priority, :integer
      field :providerId, :string
      field :requirement, :string
      field :requirementChoices, {:array, :string}
    end
  end

  defmodule ClaimRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :address, :boolean
      field :email, :boolean
      field :gender, :boolean
      field :locale, :boolean
      field :name, :boolean
      field :phone, :boolean
      field :picture, :boolean
      field :profile, :boolean
      field :username, :boolean
      field :website, :boolean
    end
  end

  defmodule ApplicationRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :claims, ClaimRepresentation
      field :name, :string
    end
  end

  defmodule ComponentExportRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :config, :map
      field :id, :string
      field :name, :string
      field :providerId, :string
      field :subComponents, :map
      field :subType, :string
    end
  end

  defmodule Composites do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :application, :map
      field :client, :map
      field :realm, {:array, :string}
    end
  end

  defmodule CredentialRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :algorithm, :string
      field :config, :map
      field :counter, :integer
      field :createdDate, :integer
      field :credentialData, :string
      field :device, :string
      field :digits, :integer
      field :hashIterations, :integer
      field :hashedSaltedValue, :string
      field :id, :string
      field :period, :integer
      field :priority, :integer
      field :salt, :string
      field :secretData, :string
      field :temporary, :boolean
      field :type, :string
      field :userLabel, :string
      field :value, :string
    end
  end

  defmodule FederatedIdentityRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :identityProvider, :string
      field :userId, :string
      field :userName, :string
    end
  end

  defmodule GroupRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :access, :map
      field :attributes, :map
      field :clientRoles, :map
      field :id, :string
      field :name, :string
      field :path, :string
      field :realmRoles, {:array, :string}
      embeds_many :subGroups, GroupRepresentation
    end
  end

  defmodule IdentityProviderMapperRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :config, :map
      field :id, :string
      field :identityProviderAlias, :string
      field :identityProviderMapper, :string
      field :name, :string
    end
  end

  defmodule IdentityProviderRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :addReadTokenRoleOnCreate, :boolean
      field :alias, :string
      field :authenticateByDefault, :boolean
      field :config, :map
      field :displayName, :string
      field :enabled, :boolean
      field :firstBrokerLoginFlowAlias, :string
      field :internalId, :string
      field :linkOnly, :boolean
      field :postBrokerLoginFlowAlias, :string
      field :providerId, :string
      field :storeToken, :boolean
      field :trustEmail, :boolean
      field :updateProfileFirstLoginMode, :string
    end
  end

  defmodule PolicyRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :config, :map
    end
  end

  defmodule ProtocolMapperRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :config, :map
      field :consentRequired, :boolean
      field :consentText, :string
      field :id, :string
      field :name, :string
      field :protocol, :string
      field :protocolMapper, :string
    end
  end

  defmodule ClientScopeRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :attributes, :map
      field :description, :string
      field :id, :string
      field :name, :string
      field :protocol, :string
      embeds_many :protocolMappers, ProtocolMapperRepresentation
    end
  end

  defmodule ClientTemplateRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :attributes, :map
      field :bearerOnly, :boolean
      field :consentRequired, :boolean
      field :description, :string
      field :directAccessGrantsEnabled, :boolean
      field :frontchannelLogout, :boolean
      field :fullScopeAllowed, :boolean
      field :id, :string
      field :implicitFlowEnabled, :boolean
      field :name, :string
      field :protocol, :string
      embeds_many :protocolMappers, ProtocolMapperRepresentation
      field :publicClient, :boolean
      field :serviceAccountsEnabled, :boolean
      field :standardFlowEnabled, :boolean
    end
  end

  defmodule RequiredActionProviderRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :alias, :string
      field :config, :map
      field :defaultAction, :boolean
      field :enabled, :boolean
      field :name, :string
      field :priority, :integer
      field :providerId, :string
    end
  end

  defmodule ResourceRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :attributes, :map
      field :displayName, :string
      field :iconUri, :string
      field :id, :string
      field :name, :string
      field :owner, :map
      field :ownerManagedAccess, :boolean
      field :scopes, {:array, :string}
      field :type, :string
      field :uris, {:array, :string}
    end
  end

  defmodule RoleRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :attributes, :map
      field :clientRole, :boolean
      field :composite, :boolean
      embeds_one :composites, Composites
      field :containerId, :string
      field :description, :string
      field :id, :string
      field :name, :string
      field :scopeParamRequired, :boolean
    end
  end

  defmodule RolesRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :application, :map
      field :client, :map
      embeds_many :realm, RoleRepresentation
    end
  end

  defmodule ScopeMappingRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :client, :string
      field :clientScope, :string
      field :clientTemplate, :string
      field :roles, {:array, :string}
      field :self, :string
    end
  end

  defmodule ScopeRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :displayName, :string
      field :iconUri, :string
      field :id, :string
      field :name, :string
      embeds_many :policies, PolicyRepresentation
      embeds_many :resources, ResourceRepresentation
    end
  end

  defmodule ResourceServerRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :allowRemoteResourceManagement, :boolean
      field :clientId, :string
      field :decisionStrategy, :string
      field :id, :string
      field :name, :string
      embeds_many :policies, PolicyRepresentation
      field :policyEnforcementMode, :string
      embeds_many :resources, ResourceRepresentation
      embeds_many :scopes, ScopeRepresentation
    end
  end

  defmodule ClientRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :access, :map
      field :adminUrl, :string
      field :alwaysDisplayInConsole, :boolean
      field :attributes, :map
      field :authenticationFlowBindingOverrides, :map
      field :authorizationServicesEnabled, :boolean
      embeds_one :authorizationSettings, ResourceServerRepresentation
      field :baseUrl, :string
      field :bearerOnly, :boolean
      field :clientAuthenticatorType, :string
      field :clientId, :string
      field :clientTemplate, :string
      field :consentRequired, :boolean
      field :defaultClientScopes, {:array, :string}
      field :defaultRoles, {:array, :string}
      field :description, :string
      field :directAccessGrantsEnabled, :boolean
      field :directGrantsOnly, :boolean
      field :enabled, :boolean
      field :frontchannelLogout, :boolean
      field :fullScopeAllowed, :boolean
      field :id, :string
      field :implicitFlowEnabled, :boolean
      field :name, :string
      field :nodeReRegistrationTimeout, :integer
      field :notBefore, :integer
      field :optionalClientScopes, {:array, :string}
      field :origin, :string
      field :protocol, :string
      embeds_many :protocolMappers, ProtocolMapperRepresentation
      field :publicClient, :boolean
      field :redirectUris, {:array, :string}
      field :registeredNodes, :map
      field :registrationAccessToken, :string
      field :rootUrl, :string
      field :secret, :string
      field :serviceAccountsEnabled, :boolean
      field :standardFlowEnabled, :boolean
      field :surrogateAuthRequired, :boolean
      field :useTemplateConfig, :boolean
      field :useTemplateMappers, :boolean
      field :useTemplateScope, :boolean
      field :webOrigins, {:array, :string}
    end
  end

  defmodule SocialLinkRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :socialProvider, :string
      field :socialUserId, :string
      field :socialUsername, :string
    end
  end

  defmodule UserConsentRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :clientId, :string
      field :createdDate, :integer
      field :grantedClientScopes, {:array, :string}
      field :grantedRealmRoles, {:array, :string}
      field :lastUpdatedDate, :integer
    end
  end

  defmodule UserFederationMapperRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :config, :map
      field :federationMapperType, :string
      field :federationProviderDisplayName, :string
      field :id, :string
      field :name, :string
    end
  end

  defmodule UserFederationProviderRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :changedSyncPeriod, :integer
      field :config, :map
      field :displayName, :string
      field :fullSyncPeriod, :integer
      field :id, :string
      field :lastSync, :integer
      field :priority, :integer
      field :providerName, :string
    end
  end

  defmodule UserRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :access, :map
      field :applicationRoles, :map
      field :attributes, :map
      embeds_many :clientConsents, UserConsentRepresentation
      field :clientRoles, :map
      field :createdTimestamp, :integer
      embeds_many :credentials, CredentialRepresentation
      field :disableableCredentialTypes, {:array, :string}
      field :email, :string
      field :emailVerified, :boolean
      field :enabled, :boolean
      embeds_many :federatedIdentities, FederatedIdentityRepresentation
      field :federationLink, :string
      field :firstName, :string
      field :groups, {:array, :string}
      field :id, :string
      field :lastName, :string
      field :notBefore, :integer
      field :origin, :string
      field :realmRoles, {:array, :string}
      field :requiredActions, {:array, :string}
      field :self, :string
      field :serviceAccountClientId, :string
      embeds_many :socialLinks, SocialLinkRepresentation
      field :totp, :boolean
      field :username, :string
    end
  end

  defmodule RealmRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :accessCodeLifespan, :integer
      field :accessCodeLifespanLogin, :integer
      field :accessCodeLifespanUserAction, :integer
      field :accessTokenLifespan, :integer
      field :accessTokenLifespanForImplicitFlow, :integer
      field :accountTheme, :string
      field :actionTokenGeneratedByAdminLifespan, :integer
      field :actionTokenGeneratedByUserLifespan, :integer
      field :adminEventsDetailsEnabled, :boolean
      field :adminEventsEnabled, :boolean
      field :adminTheme, :string
      field :applicationScopeMappings, :map
      embeds_many :applications, ApplicationRepresentation
      field :attributes, :map
      embeds_many :authenticationFlows, AuthenticationFlowRepresentation
      embeds_many :authenticatorConfig, AuthenticatorConfigRepresentation
      field :browserFlow, :string
      field :browserSecurityHeaders, :map
      field :bruteForceProtected, :boolean
      field :certificate, :string
      field :clientAuthenticationFlow, :string
      field :clientOfflineSessionIdleTimeout, :integer
      field :clientOfflineSessionMaxLifespan, :integer
      field :clientScopeMappings, :map
      embeds_many :clientScopes, ClientScopeRepresentation
      field :clientSessionIdleTimeout, :integer
      field :clientSessionMaxLifespan, :integer
      embeds_many :clientTemplates, ClientTemplateRepresentation
      embeds_many :clients, ClientRepresentation
      field :codeSecret, :string
      field :components, :map
      field :defaultDefaultClientScopes, {:array, :string}
      field :defaultGroups, {:array, :string}
      field :defaultLocale, :string
      field :defaultOptionalClientScopes, {:array, :string}
      embeds_one :defaultRole, RoleRepresentation
      field :defaultRoles, {:array, :string}
      field :defaultSignatureAlgorithm, :string
      field :directGrantFlow, :string
      field :displayName, :string
      field :displayNameHtml, :string
      field :dockerAuthenticationFlow, :string
      field :duplicateEmailsAllowed, :boolean
      field :editUsernameAllowed, :boolean
      field :emailTheme, :string
      field :enabled, :boolean
      field :enabledEventTypes, {:array, :string}
      field :eventsEnabled, :boolean
      field :eventsExpiration, :integer
      field :eventsListeners, {:array, :string}
      field :failureFactor, :integer
      embeds_many :federatedUsers, UserRepresentation
      embeds_many :groups, GroupRepresentation
      field :id, :string
      embeds_many :identityProviderMappers, IdentityProviderMapperRepresentation
      embeds_many :identityProviders, IdentityProviderRepresentation
      field :internationalizationEnabled, :boolean
      field :keycloakVersion, :string
      field :loginTheme, :string
      field :loginWithEmailAllowed, :boolean
      field :maxDeltaTimeSeconds, :integer
      field :maxFailureWaitSeconds, :integer
      field :minimumQuickLoginWaitSeconds, :integer
      field :notBefore, :integer
      field :oAuth2DeviceCodeLifespan, :integer
      field :oAuth2DevicePollingInterval, :integer
      field :oauthClients, {:array, :string}
      field :offlineSessionIdleTimeout, :integer
      field :offlineSessionMaxLifespan, :integer
      field :offlineSessionMaxLifespanEnabled, :boolean
      field :otpPolicyAlgorithm, :string
      field :otpPolicyCodeReusable, :boolean
      field :otpPolicyDigits, :integer
      field :otpPolicyInitialCounter, :integer
      field :otpPolicyLookAheadWindow, :integer
      field :otpPolicyPeriod, :integer
      field :otpPolicyType, :string
      field :otpSupportedApplications, {:array, :string}
      field :passwordCredentialGrantAllowed, :boolean
      field :passwordPolicy, :string
      field :permanentLockout, :boolean
      field :privateKey, :string
      embeds_many :protocolMappers, ProtocolMapperRepresentation
      field :publicKey, :string
      field :quickLoginCheckMilliSeconds, :integer
      field :realm, :string
      field :refreshTokenMaxReuse, :integer
      field :registrationAllowed, :boolean
      field :registrationEmailAsUsername, :boolean
      field :registrationFlow, :string
      field :rememberMe, :boolean
      embeds_many :requiredActions, RequiredActionProviderRepresentation
      field :requiredCredentials, {:array, :string}
      field :resetCredentialsFlow, :string
      field :resetPasswordAllowed, :boolean
      field :revokeRefreshToken, :boolean
      embeds_one :roles, RolesRepresentation
      embeds_many :scopeMappings, ScopeMappingRepresentation
      field :smtpServer, :map
      field :social, :boolean
      field :socialProviders, :map
      field :sslRequired, :string
      field :ssoSessionIdleTimeout, :integer
      field :ssoSessionIdleTimeoutRememberMe, :integer
      field :ssoSessionMaxLifespan, :integer
      field :ssoSessionMaxLifespanRememberMe, :integer
      field :supportedLocales, {:array, :string}
      field :updateProfileOnInitialSocialLogin, :boolean
      embeds_many :userFederationMappers, UserFederationMapperRepresentation
      embeds_many :userFederationProviders, UserFederationProviderRepresentation
      field :userManagedAccessAllowed, :boolean
      embeds_many :users, UserRepresentation
      field :verifyEmail, :boolean
      field :waitIncrementSeconds, :integer
      field :webAuthnPolicyAcceptableAaguids, {:array, :string}
      field :webAuthnPolicyAttestationConveyancePreference, :string
      field :webAuthnPolicyAuthenticatorAttachment, :string
      field :webAuthnPolicyAvoidSameAuthenticatorRegister, :boolean
      field :webAuthnPolicyCreateTimeout, :integer
      field :webAuthnPolicyPasswordlessAcceptableAaguids, {:array, :string}
      field :webAuthnPolicyPasswordlessAttestationConveyancePreference, :string
      field :webAuthnPolicyPasswordlessAuthenticatorAttachment, :string
      field :webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister, :boolean
      field :webAuthnPolicyPasswordlessCreateTimeout, :integer
      field :webAuthnPolicyPasswordlessRequireResidentKey, :string
      field :webAuthnPolicyPasswordlessRpEntityName, :string
      field :webAuthnPolicyPasswordlessRpId, :string
      field :webAuthnPolicyPasswordlessSignatureAlgorithms, {:array, :string}
      field :webAuthnPolicyPasswordlessUserVerificationRequirement, :string
      field :webAuthnPolicyRequireResidentKey, :string
      field :webAuthnPolicyRpEntityName, :string
      field :webAuthnPolicyRpId, :string
      field :webAuthnPolicySignatureAlgorithms, {:array, :string}
      field :webAuthnPolicyUserVerificationRequirement, :string
    end
  end
end
