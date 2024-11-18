defmodule CommonCore.OpenAPI.KeycloakAdminSchema do
  @moduledoc false
  defmodule BruteForceStrategy do
    @moduledoc false
    use CommonCore.Ecto.Enum, linear: "LINEAR", multiple: "MULTIPLE"
  end

  defmodule DecisionEffect do
    @moduledoc false
    use CommonCore.Ecto.Enum, permit: "PERMIT", deny: "DENY"
  end

  defmodule DecisionStrategy do
    @moduledoc false
    use CommonCore.Ecto.Enum,
      affirmative: "AFFIRMATIVE",
      unanimous: "UNANIMOUS",
      consensus: "CONSENSUS"
  end

  defmodule EnforcementMode do
    @moduledoc false
    use CommonCore.Ecto.Enum,
      permissive: "PERMISSIVE",
      enforcing: "ENFORCING",
      disabled: "DISABLED"
  end

  defmodule KeyUse do
    @moduledoc false
    use CommonCore.Ecto.Enum, sig: "SIG", enc: "ENC"
  end

  defmodule Logic do
    @moduledoc false
    use CommonCore.Ecto.Enum, positive: "POSITIVE", negative: "NEGATIVE"
  end

  defmodule MembershipType do
    @moduledoc false
    use CommonCore.Ecto.Enum, unmanaged: "UNMANAGED", managed: "MANAGED"
  end

  defmodule PolicyEnforcementMode do
    @moduledoc false
    use CommonCore.Ecto.Enum,
      enforcing: "ENFORCING",
      permissive: "PERMISSIVE",
      disabled: "DISABLED"
  end

  defmodule ScopeEnforcementMode do
    @moduledoc false
    use CommonCore.Ecto.Enum, all: "ALL", any: "ANY", disabled: "DISABLED"
  end

  defmodule UnmanagedAttributePolicy do
    @moduledoc false
    use CommonCore.Ecto.Enum,
      enabled: "ENABLED",
      admin_view: "ADMIN_VIEW",
      admin_edit: "ADMIN_EDIT"
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

  defmodule UserProfileAttributeMetadata do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :annotations, :map
      field :displayName, :string
      field :group, :string
      field :multivalued, :boolean
      field :name, :string
      field :readOnly, :boolean
      field :required, :boolean
      field :validators, :map
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

  defmodule ClientInitialAccessPresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :count, :integer
      field :expiration, :integer
      field :id, :string
      field :remainingCount, :integer
      field :timestamp, :integer
      field :token, :string
    end
  end

  defmodule Permission do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :claims, :map
      field :rsid, :string
      field :rsname, :string
      field :scopes, {:array, :string}
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

  defmodule AuthenticationExecutionRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :authenticator, :string
      field :authenticatorConfig, :string
      field :authenticatorFlow, :boolean
      field :autheticatorFlow, :boolean
      field :flowId, :string
      field :id, :string
      field :parentFlow, :string
      field :priority, :integer
      field :requirement, :string
    end
  end

  defmodule ManagementPermissionReference do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :enabled, :boolean
      field :resource, :string
      field :scopePermissions, :map
    end
  end

  defmodule UserProfileAttributeGroupMetadata do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :annotations, :map
      field :displayDescription, :string
      field :displayHeader, :string
      field :name, :string
    end
  end

  defmodule UPAttributeSelector do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :scopes, {:array, :string}
    end
  end

  defmodule Access do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :roles, {:array, :string}
      field :verify_caller, :boolean
    end
  end

  defmodule Authorization do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :permissions, Permission
    end
  end

  defmodule UPAttributePermissions do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :edit, {:array, :string}
      field :view, {:array, :string}
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

  defmodule GlobalRequestResult do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :failedRequests, {:array, :string}
      field :successRequests, {:array, :string}
    end
  end

  defmodule EventRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :clientId, :string
      field :details, :map
      field :error, :string
      field :id, :string
      field :ipAddress, :string
      field :realmId, :string
      field :sessionId, :string
      field :time, :integer
      field :type, :string
      field :userId, :string
    end
  end

  defmodule UserSessionRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :clients, :map
      field :id, :string
      field :ipAddress, :string
      field :lastAccess, :integer
      field :rememberMe, :boolean
      field :start, :integer
      field :transientUser, :boolean
      field :userId, :string
      field :username, :string
    end
  end

  defmodule RequiredActionConfigRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :config, :map
    end
  end

  defmodule ErrorRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :errorMessage, :string
      embeds_many :errors, ErrorRepresentation
      field :field, :string
      field :params, {:array, :string}
    end
  end

  defmodule ResourceType do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :groupType, :string
      field :scopeAliases, :map
      field :scopes, {:array, :string}
      field :type, :string
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
      field :federationLink, :string
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

  defmodule UPGroup do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :annotations, :map
      field :displayDescription, :string
      field :displayHeader, :string
      field :name, :string
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

  defmodule GroupRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :access, :map
      field :attributes, :map
      field :clientRoles, :map
      field :description, :string
      field :id, :string
      field :name, :string
      field :parentId, :string
      field :path, :string
      field :realmRoles, {:array, :string}
      field :subGroupCount, :integer
      embeds_many :subGroups, GroupRepresentation
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

  defmodule AbstractPolicyRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :decisionStrategy, DecisionStrategy
      field :description, :string
      field :id, :string
      field :logic, Logic
      field :name, :string
      field :owner, :string
      field :policies, {:array, :string}
      field :resourceType, :string
      field :resources, {:array, :string}
      field :resourcesData, {:array, :string}
      field :scopes, {:array, :string}
      field :scopesData, {:array, :string}
      field :type, :string
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
      field :hideOnLogin, :boolean
      field :internalId, :string
      field :linkOnly, :boolean
      field :organizationId, :string
      field :postBrokerLoginFlowAlias, :string
      field :providerId, :string
      field :storeToken, :boolean
      field :trustEmail, :boolean
      field :updateProfileFirstLogin, :boolean
      field :updateProfileFirstLoginMode, :string
    end
  end

  defmodule ClientPolicyExecutorRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :configuration, :map
      field :executor, :string
    end
  end

  defmodule ClientProfileRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :description, :string
      embeds_many :executors, ClientPolicyExecutorRepresentation
      field :name, :string
    end
  end

  defmodule ClientProfilesRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :globalProfiles, ClientProfileRepresentation
      embeds_many :profiles, ClientProfileRepresentation
    end
  end

  nil

  defmodule SocialLinkRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :socialProvider, :string
      field :socialUserId, :string
      field :socialUsername, :string
    end
  end

  defmodule PolicyEvaluationRequest do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :clientId, :string
      field :context, :map
      field :entitlements, :boolean
      field :resourceType, :string
      field :resources, {:array, :string}
      field :roleIds, {:array, :string}
      field :userId, :string
    end
  end

  defmodule PathCacheConfig do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :lifespan, :integer
      field :"max-entries", :integer
    end
  end

  defmodule KeyStoreConfig do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :format, :string
      field :keyAlias, :string
      field :keyPassword, :string
      field :keySize, :integer
      field :realmAlias, :string
      field :realmCertificate, :boolean
      field :storePassword, :string
      field :validity, :integer
    end
  end

  defmodule UserProfileMetadata do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :attributes, UserProfileAttributeMetadata
      embeds_many :groups, UserProfileAttributeGroupMetadata
    end
  end

  defmodule MemberRepresentation do
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
      field :membershipType, MembershipType
      field :notBefore, :integer
      field :origin, :string
      field :realmRoles, {:array, :string}
      field :requiredActions, {:array, :string}
      field :self, :string
      field :serviceAccountClientId, :string
      embeds_many :socialLinks, SocialLinkRepresentation
      field :totp, :boolean
      embeds_one :userProfileMetadata, UserProfileMetadata
      field :username, :string
    end
  end

  defmodule AddressClaimSet do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :country, :string
      field :formatted, :string
      field :locality, :string
      field :postal_code, :string
      field :region, :string
      field :street_address, :string
    end
  end

  defmodule IDToken do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :acr, :string
      embeds_one :address, AddressClaimSet
      field :at_hash, :string
      field :auth_time, :integer
      field :azp, :string
      field :birthdate, :string
      field :c_hash, :string
      field :claims_locales, :string
      field :email, :string
      field :email_verified, :boolean
      field :exp, :integer
      field :family_name, :string
      field :gender, :string
      field :given_name, :string
      field :iat, :integer
      field :iss, :string
      field :jti, :string
      field :locale, :string
      field :middle_name, :string
      field :name, :string
      field :nbf, :integer
      field :nickname, :string
      field :nonce, :string
      field :otherClaims, :map
      field :phone_number, :string
      field :phone_number_verified, :boolean
      field :picture, :string
      field :preferred_username, :string
      field :profile, :string
      field :s_hash, :string
      field :sid, :string
      field :sub, :string
      field :typ, :string
      field :updated_at, :integer
      field :website, :string
      field :zoneinfo, :string
    end
  end

  defmodule CertificateRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :certificate, :string
      field :kid, :string
      field :privateKey, :string
      field :publicKey, :string
    end
  end

  defmodule KeyMetadataRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :algorithm, :string
      field :certificate, :string
      field :kid, :string
      field :providerId, :string
      field :providerPriority, :integer
      field :publicKey, :string
      field :status, :string
      field :type, :string
      field :use, KeyUse
      field :validTo, :integer
    end
  end

  defmodule ConfigPropertyRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :defaultValue, :string
      field :helpText, :string
      field :label, :string
      field :name, :string
      field :options, {:array, :string}
      field :readOnly, :boolean
      field :required, :boolean
      field :secret, :boolean
      field :type, :string
    end
  end

  defmodule IdentityProviderMapperTypeRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :category, :string
      field :helpText, :string
      field :id, :string
      field :name, :string
      embeds_many :properties, ConfigPropertyRepresentation
    end
  end

  defmodule AuthenticatorConfigInfoRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :helpText, :string
      field :name, :string
      embeds_many :properties, ConfigPropertyRepresentation
      field :providerId, :string
    end
  end

  defmodule RequiredActionConfigInfoRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :properties, ConfigPropertyRepresentation
    end
  end

  defmodule UPAttributeRequired do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :roles, {:array, :string}
      field :scopes, {:array, :string}
    end
  end

  defmodule UPAttribute do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :annotations, :map
      field :displayName, :string
      field :group, :string
      field :multivalued, :boolean
      field :name, :string
      embeds_one :permissions, UPAttributePermissions
      embeds_one :required, UPAttributeRequired
      embeds_one :selector, UPAttributeSelector
      field :validations, :map
    end
  end

  defmodule UPConfig do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :attributes, UPAttribute
      embeds_many :groups, UPGroup
      field :unmanagedAttributePolicy, UnmanagedAttributePolicy
    end
  end

  defmodule ClientPolicyConditionRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :condition, :string
      field :configuration, :map
    end
  end

  defmodule ComponentRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :config, {:array, :string}
      field :id, :string
      field :name, :string
      field :parentId, :string
      field :providerId, :string
      field :providerType, :string
      field :subType, :string
    end
  end

  defmodule PropertyConfig do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :applicable, :boolean
      field :value, :string
    end
  end

  defmodule ClientTypeRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :config, PropertyConfig
      field :name, :string
      field :parent, :string
      field :provider, :string
    end
  end

  nil

  defmodule PolicyProviderRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :group, :string
      field :name, :string
      field :type, :string
    end
  end

  defmodule AuthenticationExecutionExportRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :authenticator, :string
      field :authenticatorConfig, :string
      field :authenticatorFlow, :boolean
      field :autheticatorFlow, :boolean
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

  defmodule OrganizationDomainRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :name, :string
      field :verified, :boolean
    end
  end

  defmodule OrganizationRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :alias, :string
      field :attributes, :map
      field :description, :string
      embeds_many :domains, OrganizationDomainRepresentation
      field :enabled, :boolean
      field :id, :string
      embeds_many :identityProviders, IdentityProviderRepresentation
      embeds_many :members, MemberRepresentation
      field :name, :string
      field :redirectUrl, :string
    end
  end

  defmodule KeysMetadataRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :active, :map
      embeds_many :keys, KeyMetadataRepresentation
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
      embeds_many :application, RoleRepresentation
      embeds_many :client, RoleRepresentation
      embeds_many :realm, RoleRepresentation
    end
  end

  defmodule ClientMappingsRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :client, :string
      field :id, :string
      embeds_many :mappings, RoleRepresentation
    end
  end

  defmodule AuthorizationSchema do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :resourceTypes, ResourceType
    end
  end

  defmodule AuthDetailsRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :clientId, :string
      field :ipAddress, :string
      field :realmId, :string
      field :userId, :string
    end
  end

  defmodule AdminEventRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_one :authDetails, AuthDetailsRepresentation
      field :details, :map
      field :error, :string
      field :id, :string
      field :operationType, :string
      field :realmId, :string
      field :representation, :string
      field :resourcePath, :string
      field :resourceType, :string
      field :time, :integer
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

  defmodule ClientInitialAccessCreatePresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :count, :integer
      field :expiration, :integer
    end
  end

  defmodule ClientPolicyRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :conditions, ClientPolicyConditionRepresentation
      field :description, :string
      field :enabled, :boolean
      field :name, :string
      field :profiles, {:array, :string}
    end
  end

  defmodule ClientPoliciesRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :globalPolicies, ClientPolicyRepresentation
      embeds_many :policies, ClientPolicyRepresentation
    end
  end

  defmodule ClientTypesRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :"client-types", ClientTypeRepresentation
      embeds_many :"global-client-types", ClientTypeRepresentation
    end
  end

  defmodule ComponentExportRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :config, {:array, :string}
      field :id, :string
      field :name, :string
      field :providerId, :string
      field :subComponents, {:array, :map}
      field :subType, :string
    end
  end

  defmodule ComponentTypeRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :helpText, :string
      field :id, :string
      field :metadata, :map
      embeds_many :properties, ConfigPropertyRepresentation
    end
  end

  defmodule Confirmation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :jkt, :string
      field :"x5t#S256", :string
    end
  end

  defmodule AccessToken do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :acr, :string
      embeds_one :address, AddressClaimSet
      field :"allowed-origins", {:array, :string}
      field :at_hash, :string
      field :auth_time, :integer
      embeds_one :authorization, Authorization
      field :azp, :string
      field :birthdate, :string
      field :c_hash, :string
      field :claims_locales, :string
      embeds_one :cnf, Confirmation
      field :email, :string
      field :email_verified, :boolean
      field :exp, :integer
      field :family_name, :string
      field :gender, :string
      field :given_name, :string
      field :iat, :integer
      field :iss, :string
      field :jti, :string
      field :locale, :string
      field :middle_name, :string
      field :name, :string
      field :nbf, :integer
      field :nickname, :string
      field :nonce, :string
      field :otherClaims, :map
      field :phone_number, :string
      field :phone_number_verified, :boolean
      field :picture, :string
      field :preferred_username, :string
      field :profile, :string
      embeds_one :realm_access, Access
      embeds_many :resource_access, Access
      field :s_hash, :string
      field :scope, :string
      field :sid, :string
      field :sub, :string
      field :"trusted-certs", {:array, :string}
      field :typ, :string
      field :updated_at, :integer
      field :website, :string
      field :zoneinfo, :string
    end
  end

  defmodule MappingsRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :clientMappings, ClientMappingsRepresentation
      embeds_many :realmMappings, RoleRepresentation
    end
  end

  defmodule MethodConfig do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :method, :string
      field :scopes, {:array, :string}
      field :"scopes-enforcement-mode", ScopeEnforcementMode
    end
  end

  defmodule PathConfig do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :"claim-information-point", :map
      field :"enforcement-mode", EnforcementMode
      field :id, :string
      field :invalidated, :boolean
      embeds_many :methods, MethodConfig
      field :name, :string
      field :path, :string
      field :scopes, {:array, :string}
      field :static, :boolean
      field :staticPath, :boolean
      field :type, :string
    end
  end

  defmodule PolicyEnforcerConfig do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :"auth-server-url", :string
      field :"claim-information-point", :map
      field :credentials, :map
      field :"enforcement-mode", EnforcementMode
      field :"http-method-as-scope", :boolean
      field :"lazy-load-paths", :boolean
      field :"on-deny-redirect-to", :string
      embeds_one :"path-cache", PathCacheConfig
      embeds_many :paths, PathConfig
      field :realm, :string
      field :resource, :string
      field :"user-managed-access", :map
    end
  end

  defmodule InstallationAdapterConfig do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :"auth-server-url", :string
      field :"bearer-only", :boolean
      field :"confidential-port", :integer
      field :credentials, :map
      embeds_one :"policy-enforcer", PolicyEnforcerConfig
      field :"public-client", :boolean
      field :realm, :string
      field :"realm-public-key", :string
      field :resource, :string
      field :"ssl-required", :string
      field :"use-resource-role-mappings", :boolean
      field :"verify-token-audience", :boolean
    end
  end

  defmodule PolicyResultRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      embeds_many :associatedPolicies, PolicyResultRepresentation
      field :policy, :map
      field :resourceType, :string
      field :scopes, {:array, :string}
      field :status, DecisionEffect
    end
  end

  defmodule EvaluationResultRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :allowedScopes, {:array, :string}
      field :deniedScopes, {:array, :string}
      embeds_many :policies, PolicyResultRepresentation
      field :resource, :map
      field :scopes, {:array, :string}
      field :status, DecisionEffect
    end
  end

  defmodule PolicyEvaluationResponse do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :entitlements, :boolean
      embeds_many :results, EvaluationResultRepresentation
      embeds_one :rpt, AccessToken
      field :status, DecisionEffect
    end
  end

  defmodule ProtocolMapperEvaluationRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :containerId, :string
      field :containerName, :string
      field :containerType, :string
      field :mapperId, :string
      field :mapperName, :string
      field :protocolMapper, :string
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

  defmodule PublishedRealmRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :"account-service", :string
      field :public_key, :string
      field :realm, :string
      field :"token-service", :string
      field :"tokens-not-before", :integer
    end
  end

  defmodule RealmEventsConfigRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :adminEventsDetailsEnabled, :boolean
      field :adminEventsEnabled, :boolean
      field :enabledEventTypes, {:array, :string}
      field :eventsEnabled, :boolean
      field :eventsExpiration, :integer
      field :eventsListeners, {:array, :string}
    end
  end

  defmodule ResourceServerRepresentation do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :allowRemoteResourceManagement, :boolean
      embeds_one :authorizationSchema, AuthorizationSchema
      field :clientId, :string
      field :decisionStrategy, DecisionStrategy
      field :id, :string
      field :name, :string
      field :policies, {:array, :string}
      field :policyEnforcementMode, PolicyEnforcementMode
      field :resources, {:array, :string}
      field :scopes, {:array, :string}
    end
  end

  defmodule ApplicationRepresentation do
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
      embeds_many :claims, ClaimRepresentation
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
      field :type, :string
      field :useTemplateConfig, :boolean
      field :useTemplateMappers, :boolean
      field :useTemplateScope, :boolean
      field :webOrigins, {:array, :string}
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
      field :type, :string
      field :useTemplateConfig, :boolean
      field :useTemplateMappers, :boolean
      field :useTemplateScope, :boolean
      field :webOrigins, {:array, :string}
    end
  end

  defmodule OAuthClientRepresentation do
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
      embeds_many :claims, ClaimRepresentation
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
      field :type, :string
      field :useTemplateConfig, :boolean
      field :useTemplateMappers, :boolean
      field :useTemplateScope, :boolean
      field :webOrigins, {:array, :string}
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
      embeds_one :userProfileMetadata, UserProfileMetadata
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
      embeds_one :adminPermissionsClient, ClientRepresentation
      field :adminPermissionsEnabled, :boolean
      field :adminTheme, :string
      embeds_many :applicationScopeMappings, ScopeMappingRepresentation
      embeds_many :applications, ApplicationRepresentation
      field :attributes, :map
      embeds_many :authenticationFlows, AuthenticationFlowRepresentation
      embeds_many :authenticatorConfig, AuthenticatorConfigRepresentation
      field :browserFlow, :string
      field :browserSecurityHeaders, :map
      field :bruteForceProtected, :boolean
      field :bruteForceStrategy, BruteForceStrategy
      field :certificate, :string
      field :clientAuthenticationFlow, :string
      field :clientOfflineSessionIdleTimeout, :integer
      field :clientOfflineSessionMaxLifespan, :integer
      embeds_one :clientPolicies, ClientPoliciesRepresentation
      embeds_one :clientProfiles, ClientProfilesRepresentation
      embeds_many :clientScopeMappings, ScopeMappingRepresentation
      embeds_many :clientScopes, ClientScopeRepresentation
      field :clientSessionIdleTimeout, :integer
      field :clientSessionMaxLifespan, :integer
      embeds_many :clientTemplates, ClientTemplateRepresentation
      embeds_many :clients, ClientRepresentation
      field :codeSecret, :string
      field :components, {:array, :map}
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
      field :firstBrokerLoginFlow, :string
      embeds_many :groups, GroupRepresentation
      field :id, :string
      embeds_many :identityProviderMappers, IdentityProviderMapperRepresentation
      embeds_many :identityProviders, IdentityProviderRepresentation
      field :internationalizationEnabled, :boolean
      field :keycloakVersion, :string
      field :localizationTexts, :map
      field :loginTheme, :string
      field :loginWithEmailAllowed, :boolean
      field :maxDeltaTimeSeconds, :integer
      field :maxFailureWaitSeconds, :integer
      field :maxTemporaryLockouts, :integer
      field :minimumQuickLoginWaitSeconds, :integer
      field :notBefore, :integer
      field :oAuth2DeviceCodeLifespan, :integer
      field :oAuth2DevicePollingInterval, :integer
      field :oauth2DeviceCodeLifespan, :integer
      field :oauth2DevicePollingInterval, :integer
      field :oauthClients, {:array, :string}
      field :offlineSessionIdleTimeout, :integer
      field :offlineSessionMaxLifespan, :integer
      field :offlineSessionMaxLifespanEnabled, :boolean
      embeds_many :organizations, OrganizationRepresentation
      field :organizationsEnabled, :boolean
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
      field :realmCacheEnabled, :boolean
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
      field :userCacheEnabled, :boolean
      embeds_many :userFederationMappers, UserFederationMapperRepresentation
      embeds_many :userFederationProviders, UserFederationProviderRepresentation
      field :userManagedAccessAllowed, :boolean
      embeds_many :users, UserRepresentation
      field :verifiableCredentialsEnabled, :boolean
      field :verifyEmail, :boolean
      field :waitIncrementSeconds, :integer
      field :webAuthnPolicyAcceptableAaguids, {:array, :string}
      field :webAuthnPolicyAttestationConveyancePreference, :string
      field :webAuthnPolicyAuthenticatorAttachment, :string
      field :webAuthnPolicyAvoidSameAuthenticatorRegister, :boolean
      field :webAuthnPolicyCreateTimeout, :integer
      field :webAuthnPolicyExtraOrigins, {:array, :string}
      field :webAuthnPolicyPasswordlessAcceptableAaguids, {:array, :string}
      field :webAuthnPolicyPasswordlessAttestationConveyancePreference, :string
      field :webAuthnPolicyPasswordlessAuthenticatorAttachment, :string
      field :webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister, :boolean
      field :webAuthnPolicyPasswordlessCreateTimeout, :integer
      field :webAuthnPolicyPasswordlessExtraOrigins, {:array, :string}
      field :webAuthnPolicyPasswordlessPasskeysEnabled, :boolean
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
