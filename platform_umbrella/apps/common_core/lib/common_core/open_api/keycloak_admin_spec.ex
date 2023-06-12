defmodule CommonCore.OpenApi.KeycloakAdminSpec do
  use TypedStruct
  import CommonCore.OpenApi.AtomTools

  defmodule AuthenticationExecutionExportRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :flowAlias, String.t(), enforce: false
      field :userSetupAllowed, boolean(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(AuthenticationExecutionExportRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule AuthenticationFlowRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :alias, String.t(), enforce: false

      field(:authenticationExecutions, list(AuthenticationExecutionExportRepresentation.t()),
        enforce: false
      )

      field :builtIn, boolean(), enforce: false
      field :description, String.t(), enforce: false
      field :id, String.t(), enforce: false
      field :providerId, String.t(), enforce: false
      field :topLevel, boolean(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(AuthenticationFlowRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"authenticationExecutions", items}) do
        {:authenticationExecutions,
         AuthenticationExecutionExportRepresentation.decode_list(items)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule AuthenticatorConfigRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :alias, String.t(), enforce: false
      field :config, map(), enforce: false
      field :id, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(AuthenticatorConfigRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule ClaimRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :address, boolean(), enforce: false
      field :email, boolean(), enforce: false
      field :gender, boolean(), enforce: false
      field :locale, boolean(), enforce: false
      field :name, boolean(), enforce: false
      field :phone, boolean(), enforce: false
      field :picture, boolean(), enforce: false
      field :profile, boolean(), enforce: false
      field :username, boolean(), enforce: false
      field :website, boolean(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(ClaimRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule ApplicationRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :claims, ClaimRepresentation.t(), enforce: false
      field :name, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(ApplicationRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"claims", value}) do
        {:claims, ClaimRepresentation.decode(value)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule ComponentExportRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :config, map(), enforce: false
      field :id, String.t(), enforce: false
      field :name, String.t(), enforce: false
      field :providerId, String.t(), enforce: false
      field :subComponents, map(), enforce: false
      field :subType, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(ComponentExportRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule Composites do
    @derive Jason.Encoder
    typedstruct do
      field :application, map(), enforce: false
      field :client, map(), enforce: false
      field :realm, list(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(Composites, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule CredentialRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :algorithm, String.t(), enforce: false
      field :config, map(), enforce: false
      field :counter, integer(), enforce: false
      field :createdDate, integer(), enforce: false
      field :credentialData, String.t(), enforce: false
      field :device, String.t(), enforce: false
      field :digits, integer(), enforce: false
      field :hashIterations, integer(), enforce: false
      field :hashedSaltedValue, String.t(), enforce: false
      field :id, String.t(), enforce: false
      field :period, integer(), enforce: false
      field :priority, integer(), enforce: false
      field :salt, String.t(), enforce: false
      field :secretData, String.t(), enforce: false
      field :temporary, boolean(), enforce: false
      field :type, String.t(), enforce: false
      field :userLabel, String.t(), enforce: false
      field :value, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(CredentialRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule FederatedIdentityRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :identityProvider, String.t(), enforce: false
      field :userId, String.t(), enforce: false
      field :userName, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(FederatedIdentityRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule GroupRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :access, map(), enforce: false
      field :attributes, map(), enforce: false
      field :clientRoles, map(), enforce: false
      field :id, String.t(), enforce: false
      field :name, String.t(), enforce: false
      field :path, String.t(), enforce: false
      field :realmRoles, list(), enforce: false
      field :subGroups, list(GroupRepresentation.t()), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(GroupRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"subGroups", items}) do
        {:subGroups, GroupRepresentation.decode_list(items)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule IdentityProviderMapperRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :config, map(), enforce: false
      field :id, String.t(), enforce: false
      field :identityProviderAlias, String.t(), enforce: false
      field :identityProviderMapper, String.t(), enforce: false
      field :name, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(IdentityProviderMapperRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule IdentityProviderRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :addReadTokenRoleOnCreate, boolean(), enforce: false
      field :alias, String.t(), enforce: false
      field :authenticateByDefault, boolean(), enforce: false
      field :config, map(), enforce: false
      field :displayName, String.t(), enforce: false
      field :enabled, boolean(), enforce: false
      field :firstBrokerLoginFlowAlias, String.t(), enforce: false
      field :internalId, String.t(), enforce: false
      field :linkOnly, boolean(), enforce: false
      field :postBrokerLoginFlowAlias, String.t(), enforce: false
      field :providerId, String.t(), enforce: false
      field :storeToken, boolean(), enforce: false
      field :trustEmail, boolean(), enforce: false
      field :updateProfileFirstLoginMode, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(IdentityProviderRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule PolicyRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :config, map(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(PolicyRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule ProtocolMapperRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :config, map(), enforce: false
      field :consentRequired, boolean(), enforce: false
      field :consentText, String.t(), enforce: false
      field :id, String.t(), enforce: false
      field :name, String.t(), enforce: false
      field :protocol, String.t(), enforce: false
      field :protocolMapper, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(ProtocolMapperRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule ClientScopeRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :attributes, map(), enforce: false
      field :description, String.t(), enforce: false
      field :id, String.t(), enforce: false
      field :name, String.t(), enforce: false
      field :protocol, String.t(), enforce: false
      field :protocolMappers, list(ProtocolMapperRepresentation.t()), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(ClientScopeRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"protocolMappers", items}) do
        {:protocolMappers, ProtocolMapperRepresentation.decode_list(items)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule ClientTemplateRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :attributes, map(), enforce: false
      field :bearerOnly, boolean(), enforce: false
      field :consentRequired, boolean(), enforce: false
      field :description, String.t(), enforce: false
      field :directAccessGrantsEnabled, boolean(), enforce: false
      field :frontchannelLogout, boolean(), enforce: false
      field :fullScopeAllowed, boolean(), enforce: false
      field :id, String.t(), enforce: false
      field :implicitFlowEnabled, boolean(), enforce: false
      field :name, String.t(), enforce: false
      field :protocol, String.t(), enforce: false
      field :protocolMappers, list(ProtocolMapperRepresentation.t()), enforce: false
      field :publicClient, boolean(), enforce: false
      field :serviceAccountsEnabled, boolean(), enforce: false
      field :standardFlowEnabled, boolean(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(ClientTemplateRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"protocolMappers", items}) do
        {:protocolMappers, ProtocolMapperRepresentation.decode_list(items)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule RequiredActionProviderRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :alias, String.t(), enforce: false
      field :config, map(), enforce: false
      field :defaultAction, boolean(), enforce: false
      field :enabled, boolean(), enforce: false
      field :name, String.t(), enforce: false
      field :priority, integer(), enforce: false
      field :providerId, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(RequiredActionProviderRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule ResourceRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :attributes, map(), enforce: false
      field :displayName, String.t(), enforce: false
      field :iconUri, String.t(), enforce: false
      field :id, String.t(), enforce: false
      field :name, String.t(), enforce: false
      field :owner, map(), enforce: false
      field :ownerManagedAccess, boolean(), enforce: false
      field :scopes, list(), enforce: false
      field :type, String.t(), enforce: false
      field :uris, list(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(ResourceRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule RoleRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :attributes, map(), enforce: false
      field :clientRole, boolean(), enforce: false
      field :composite, boolean(), enforce: false
      field :composites, Composites.t(), enforce: false
      field :containerId, String.t(), enforce: false
      field :description, String.t(), enforce: false
      field :id, String.t(), enforce: false
      field :name, String.t(), enforce: false
      field :scopeParamRequired, boolean(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(RoleRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"composites", value}) do
        {:composites, Composites.decode(value)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule RolesRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :application, map(), enforce: false
      field :client, map(), enforce: false
      field :realm, list(RoleRepresentation.t()), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(RolesRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"realm", items}) do
        {:realm, RoleRepresentation.decode_list(items)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule ScopeMappingRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :client, String.t(), enforce: false
      field :clientScope, String.t(), enforce: false
      field :clientTemplate, String.t(), enforce: false
      field :roles, list(), enforce: false
      field :self, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(ScopeMappingRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule ScopeRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :displayName, String.t(), enforce: false
      field :iconUri, String.t(), enforce: false
      field :id, String.t(), enforce: false
      field :name, String.t(), enforce: false
      field :policies, list(PolicyRepresentation.t()), enforce: false
      field :resources, list(ResourceRepresentation.t()), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(ScopeRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"policies", items}) do
        {:policies, PolicyRepresentation.decode_list(items)}
      end

      defp decode_property({"resources", items}) do
        {:resources, ResourceRepresentation.decode_list(items)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule ResourceServerRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :allowRemoteResourceManagement, boolean(), enforce: false
      field :clientId, String.t(), enforce: false
      field :decisionStrategy, String.t(), enforce: false
      field :id, String.t(), enforce: false
      field :name, String.t(), enforce: false
      field :policies, list(PolicyRepresentation.t()), enforce: false
      field :policyEnforcementMode, String.t(), enforce: false
      field :resources, list(ResourceRepresentation.t()), enforce: false
      field :scopes, list(ScopeRepresentation.t()), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(ResourceServerRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"policies", items}) do
        {:policies, PolicyRepresentation.decode_list(items)}
      end

      defp decode_property({"resources", items}) do
        {:resources, ResourceRepresentation.decode_list(items)}
      end

      defp decode_property({"scopes", items}) do
        {:scopes, ScopeRepresentation.decode_list(items)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule ClientRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :access, map(), enforce: false
      field :adminUrl, String.t(), enforce: false
      field :alwaysDisplayInConsole, boolean(), enforce: false
      field :attributes, map(), enforce: false
      field :authenticationFlowBindingOverrides, map(), enforce: false
      field :authorizationServicesEnabled, boolean(), enforce: false
      field :authorizationSettings, ResourceServerRepresentation.t(), enforce: false
      field :baseUrl, String.t(), enforce: false
      field :bearerOnly, boolean(), enforce: false
      field :clientAuthenticatorType, String.t(), enforce: false
      field :clientId, String.t(), enforce: false
      field :clientTemplate, String.t(), enforce: false
      field :consentRequired, boolean(), enforce: false
      field :defaultClientScopes, list(), enforce: false
      field :defaultRoles, list(), enforce: false
      field :description, String.t(), enforce: false
      field :directAccessGrantsEnabled, boolean(), enforce: false
      field :directGrantsOnly, boolean(), enforce: false
      field :enabled, boolean(), enforce: false
      field :frontchannelLogout, boolean(), enforce: false
      field :fullScopeAllowed, boolean(), enforce: false
      field :id, String.t(), enforce: false
      field :implicitFlowEnabled, boolean(), enforce: false
      field :name, String.t(), enforce: false
      field :nodeReRegistrationTimeout, integer(), enforce: false
      field :notBefore, integer(), enforce: false
      field :optionalClientScopes, list(), enforce: false
      field :origin, String.t(), enforce: false
      field :protocol, String.t(), enforce: false
      field :protocolMappers, list(ProtocolMapperRepresentation.t()), enforce: false
      field :publicClient, boolean(), enforce: false
      field :redirectUris, list(), enforce: false
      field :registeredNodes, map(), enforce: false
      field :registrationAccessToken, String.t(), enforce: false
      field :rootUrl, String.t(), enforce: false
      field :secret, String.t(), enforce: false
      field :serviceAccountsEnabled, boolean(), enforce: false
      field :standardFlowEnabled, boolean(), enforce: false
      field :surrogateAuthRequired, boolean(), enforce: false
      field :useTemplateConfig, boolean(), enforce: false
      field :useTemplateMappers, boolean(), enforce: false
      field :useTemplateScope, boolean(), enforce: false
      field :webOrigins, list(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(ClientRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"authorizationSettings", value}) do
        {:authorizationSettings, ResourceServerRepresentation.decode(value)}
      end

      defp decode_property({"protocolMappers", items}) do
        {:protocolMappers, ProtocolMapperRepresentation.decode_list(items)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule SocialLinkRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :socialProvider, String.t(), enforce: false
      field :socialUserId, String.t(), enforce: false
      field :socialUsername, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(SocialLinkRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule UserConsentRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :clientId, String.t(), enforce: false
      field :createdDate, integer(), enforce: false
      field :grantedClientScopes, list(), enforce: false
      field :grantedRealmRoles, list(), enforce: false
      field :lastUpdatedDate, integer(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(UserConsentRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule UserFederationMapperRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :config, map(), enforce: false
      field :federationMapperType, String.t(), enforce: false
      field :federationProviderDisplayName, String.t(), enforce: false
      field :id, String.t(), enforce: false
      field :name, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(UserFederationMapperRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule UserFederationProviderRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :changedSyncPeriod, integer(), enforce: false
      field :config, map(), enforce: false
      field :displayName, String.t(), enforce: false
      field :fullSyncPeriod, integer(), enforce: false
      field :id, String.t(), enforce: false
      field :lastSync, integer(), enforce: false
      field :priority, integer(), enforce: false
      field :providerName, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(UserFederationProviderRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule UserRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :access, map(), enforce: false
      field :applicationRoles, map(), enforce: false
      field :attributes, map(), enforce: false
      field :clientConsents, list(UserConsentRepresentation.t()), enforce: false
      field :clientRoles, map(), enforce: false
      field :createdTimestamp, integer(), enforce: false
      field :credentials, list(CredentialRepresentation.t()), enforce: false
      field :disableableCredentialTypes, list(), enforce: false
      field :email, String.t(), enforce: false
      field :emailVerified, boolean(), enforce: false
      field :enabled, boolean(), enforce: false
      field :federatedIdentities, list(FederatedIdentityRepresentation.t()), enforce: false
      field :federationLink, String.t(), enforce: false
      field :firstName, String.t(), enforce: false
      field :groups, list(), enforce: false
      field :id, String.t(), enforce: false
      field :lastName, String.t(), enforce: false
      field :notBefore, integer(), enforce: false
      field :origin, String.t(), enforce: false
      field :realmRoles, list(), enforce: false
      field :requiredActions, list(), enforce: false
      field :self, String.t(), enforce: false
      field :serviceAccountClientId, String.t(), enforce: false
      field :socialLinks, list(SocialLinkRepresentation.t()), enforce: false
      field :totp, boolean(), enforce: false
      field :username, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(UserRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"clientConsents", items}) do
        {:clientConsents, UserConsentRepresentation.decode_list(items)}
      end

      defp decode_property({"credentials", items}) do
        {:credentials, CredentialRepresentation.decode_list(items)}
      end

      defp decode_property({"federatedIdentities", items}) do
        {:federatedIdentities, FederatedIdentityRepresentation.decode_list(items)}
      end

      defp decode_property({"socialLinks", items}) do
        {:socialLinks, SocialLinkRepresentation.decode_list(items)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end

  defmodule RealmRepresentation do
    @derive Jason.Encoder
    typedstruct do
      field :accessCodeLifespan, integer(), enforce: false
      field :accessCodeLifespanLogin, integer(), enforce: false
      field :accessCodeLifespanUserAction, integer(), enforce: false
      field :accessTokenLifespan, integer(), enforce: false
      field :accessTokenLifespanForImplicitFlow, integer(), enforce: false
      field :accountTheme, String.t(), enforce: false
      field :actionTokenGeneratedByAdminLifespan, integer(), enforce: false
      field :actionTokenGeneratedByUserLifespan, integer(), enforce: false
      field :adminEventsDetailsEnabled, boolean(), enforce: false
      field :adminEventsEnabled, boolean(), enforce: false
      field :adminTheme, String.t(), enforce: false
      field :applicationScopeMappings, map(), enforce: false
      field :applications, list(ApplicationRepresentation.t()), enforce: false
      field :attributes, map(), enforce: false
      field :authenticationFlows, list(AuthenticationFlowRepresentation.t()), enforce: false
      field :authenticatorConfig, list(AuthenticatorConfigRepresentation.t()), enforce: false
      field :browserFlow, String.t(), enforce: false
      field :browserSecurityHeaders, map(), enforce: false
      field :bruteForceProtected, boolean(), enforce: false
      field :certificate, String.t(), enforce: false
      field :clientAuthenticationFlow, String.t(), enforce: false
      field :clientOfflineSessionIdleTimeout, integer(), enforce: false
      field :clientOfflineSessionMaxLifespan, integer(), enforce: false
      field :clientScopeMappings, map(), enforce: false
      field :clientScopes, list(ClientScopeRepresentation.t()), enforce: false
      field :clientSessionIdleTimeout, integer(), enforce: false
      field :clientSessionMaxLifespan, integer(), enforce: false
      field :clientTemplates, list(ClientTemplateRepresentation.t()), enforce: false
      field :clients, list(ClientRepresentation.t()), enforce: false
      field :codeSecret, String.t(), enforce: false
      field :components, map(), enforce: false
      field :defaultDefaultClientScopes, list(), enforce: false
      field :defaultGroups, list(), enforce: false
      field :defaultLocale, String.t(), enforce: false
      field :defaultOptionalClientScopes, list(), enforce: false
      field :defaultRole, RoleRepresentation.t(), enforce: false
      field :defaultRoles, list(), enforce: false
      field :defaultSignatureAlgorithm, String.t(), enforce: false
      field :directGrantFlow, String.t(), enforce: false
      field :displayName, String.t(), enforce: false
      field :displayNameHtml, String.t(), enforce: false
      field :dockerAuthenticationFlow, String.t(), enforce: false
      field :duplicateEmailsAllowed, boolean(), enforce: false
      field :editUsernameAllowed, boolean(), enforce: false
      field :emailTheme, String.t(), enforce: false
      field :enabled, boolean(), enforce: false
      field :enabledEventTypes, list(), enforce: false
      field :eventsEnabled, boolean(), enforce: false
      field :eventsExpiration, integer(), enforce: false
      field :eventsListeners, list(), enforce: false
      field :failureFactor, integer(), enforce: false
      field :federatedUsers, list(UserRepresentation.t()), enforce: false
      field :groups, list(GroupRepresentation.t()), enforce: false
      field :id, String.t(), enforce: false

      field(:identityProviderMappers, list(IdentityProviderMapperRepresentation.t()),
        enforce: false
      )

      field :identityProviders, list(IdentityProviderRepresentation.t()), enforce: false
      field :internationalizationEnabled, boolean(), enforce: false
      field :keycloakVersion, String.t(), enforce: false
      field :loginTheme, String.t(), enforce: false
      field :loginWithEmailAllowed, boolean(), enforce: false
      field :maxDeltaTimeSeconds, integer(), enforce: false
      field :maxFailureWaitSeconds, integer(), enforce: false
      field :minimumQuickLoginWaitSeconds, integer(), enforce: false
      field :notBefore, integer(), enforce: false
      field :oAuth2DeviceCodeLifespan, integer(), enforce: false
      field :oAuth2DevicePollingInterval, integer(), enforce: false
      field :oauthClients, list(), enforce: false
      field :offlineSessionIdleTimeout, integer(), enforce: false
      field :offlineSessionMaxLifespan, integer(), enforce: false
      field :offlineSessionMaxLifespanEnabled, boolean(), enforce: false
      field :otpPolicyAlgorithm, String.t(), enforce: false
      field :otpPolicyCodeReusable, boolean(), enforce: false
      field :otpPolicyDigits, integer(), enforce: false
      field :otpPolicyInitialCounter, integer(), enforce: false
      field :otpPolicyLookAheadWindow, integer(), enforce: false
      field :otpPolicyPeriod, integer(), enforce: false
      field :otpPolicyType, String.t(), enforce: false
      field :otpSupportedApplications, list(), enforce: false
      field :passwordCredentialGrantAllowed, boolean(), enforce: false
      field :passwordPolicy, String.t(), enforce: false
      field :permanentLockout, boolean(), enforce: false
      field :privateKey, String.t(), enforce: false
      field :protocolMappers, list(ProtocolMapperRepresentation.t()), enforce: false
      field :publicKey, String.t(), enforce: false
      field :quickLoginCheckMilliSeconds, integer(), enforce: false
      field :realm, String.t(), enforce: false
      field :refreshTokenMaxReuse, integer(), enforce: false
      field :registrationAllowed, boolean(), enforce: false
      field :registrationEmailAsUsername, boolean(), enforce: false
      field :registrationFlow, String.t(), enforce: false
      field :rememberMe, boolean(), enforce: false
      field :requiredActions, list(RequiredActionProviderRepresentation.t()), enforce: false
      field :requiredCredentials, list(), enforce: false
      field :resetCredentialsFlow, String.t(), enforce: false
      field :resetPasswordAllowed, boolean(), enforce: false
      field :revokeRefreshToken, boolean(), enforce: false
      field :roles, RolesRepresentation.t(), enforce: false
      field :scopeMappings, list(ScopeMappingRepresentation.t()), enforce: false
      field :smtpServer, map(), enforce: false
      field :social, boolean(), enforce: false
      field :socialProviders, map(), enforce: false
      field :sslRequired, String.t(), enforce: false
      field :ssoSessionIdleTimeout, integer(), enforce: false
      field :ssoSessionIdleTimeoutRememberMe, integer(), enforce: false
      field :ssoSessionMaxLifespan, integer(), enforce: false
      field :ssoSessionMaxLifespanRememberMe, integer(), enforce: false
      field :supportedLocales, list(), enforce: false
      field :updateProfileOnInitialSocialLogin, boolean(), enforce: false
      field :userFederationMappers, list(UserFederationMapperRepresentation.t()), enforce: false

      field(:userFederationProviders, list(UserFederationProviderRepresentation.t()),
        enforce: false
      )

      field :userManagedAccessAllowed, boolean(), enforce: false
      field :users, list(UserRepresentation.t()), enforce: false
      field :verifyEmail, boolean(), enforce: false
      field :waitIncrementSeconds, integer(), enforce: false
      field :webAuthnPolicyAcceptableAaguids, list(), enforce: false
      field :webAuthnPolicyAttestationConveyancePreference, String.t(), enforce: false
      field :webAuthnPolicyAuthenticatorAttachment, String.t(), enforce: false
      field :webAuthnPolicyAvoidSameAuthenticatorRegister, boolean(), enforce: false
      field :webAuthnPolicyCreateTimeout, integer(), enforce: false
      field :webAuthnPolicyPasswordlessAcceptableAaguids, list(), enforce: false

      field :webAuthnPolicyPasswordlessAttestationConveyancePreference, String.t(), enforce: false

      field :webAuthnPolicyPasswordlessAuthenticatorAttachment, String.t(), enforce: false
      field :webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister, boolean(), enforce: false
      field :webAuthnPolicyPasswordlessCreateTimeout, integer(), enforce: false
      field :webAuthnPolicyPasswordlessRequireResidentKey, String.t(), enforce: false
      field :webAuthnPolicyPasswordlessRpEntityName, String.t(), enforce: false
      field :webAuthnPolicyPasswordlessRpId, String.t(), enforce: false
      field :webAuthnPolicyPasswordlessSignatureAlgorithms, list(), enforce: false
      field :webAuthnPolicyPasswordlessUserVerificationRequirement, String.t(), enforce: false
      field :webAuthnPolicyRequireResidentKey, String.t(), enforce: false
      field :webAuthnPolicyRpEntityName, String.t(), enforce: false
      field :webAuthnPolicyRpId, String.t(), enforce: false
      field :webAuthnPolicySignatureAlgorithms, list(), enforce: false
      field :webAuthnPolicyUserVerificationRequirement, String.t(), enforce: false
    end

    (
      def decode(args) do
        fields = args |> Enum.map(&decode_property/1) |> Enum.reject(&is_nil/1)
        struct(RealmRepresentation, fields)
      end

      def decode_list(items) do
        Enum.map(items, &decode/1)
      end

      defp decode_property({"applications", items}) do
        {:applications, ApplicationRepresentation.decode_list(items)}
      end

      defp decode_property({"authenticationFlows", items}) do
        {:authenticationFlows, AuthenticationFlowRepresentation.decode_list(items)}
      end

      defp decode_property({"authenticatorConfig", items}) do
        {:authenticatorConfig, AuthenticatorConfigRepresentation.decode_list(items)}
      end

      defp decode_property({"clientScopes", items}) do
        {:clientScopes, ClientScopeRepresentation.decode_list(items)}
      end

      defp decode_property({"clientTemplates", items}) do
        {:clientTemplates, ClientTemplateRepresentation.decode_list(items)}
      end

      defp decode_property({"clients", items}) do
        {:clients, ClientRepresentation.decode_list(items)}
      end

      defp decode_property({"defaultRole", value}) do
        {:defaultRole, RoleRepresentation.decode(value)}
      end

      defp decode_property({"federatedUsers", items}) do
        {:federatedUsers, UserRepresentation.decode_list(items)}
      end

      defp decode_property({"groups", items}) do
        {:groups, GroupRepresentation.decode_list(items)}
      end

      defp decode_property({"identityProviderMappers", items}) do
        {:identityProviderMappers, IdentityProviderMapperRepresentation.decode_list(items)}
      end

      defp decode_property({"identityProviders", items}) do
        {:identityProviders, IdentityProviderRepresentation.decode_list(items)}
      end

      defp decode_property({"protocolMappers", items}) do
        {:protocolMappers, ProtocolMapperRepresentation.decode_list(items)}
      end

      defp decode_property({"requiredActions", items}) do
        {:requiredActions, RequiredActionProviderRepresentation.decode_list(items)}
      end

      defp decode_property({"roles", value}) do
        {:roles, RolesRepresentation.decode(value)}
      end

      defp decode_property({"scopeMappings", items}) do
        {:scopeMappings, ScopeMappingRepresentation.decode_list(items)}
      end

      defp decode_property({"userFederationMappers", items}) do
        {:userFederationMappers, UserFederationMapperRepresentation.decode_list(items)}
      end

      defp decode_property({"userFederationProviders", items}) do
        {:userFederationProviders, UserFederationProviderRepresentation.decode_list(items)}
      end

      defp decode_property({"users", items}) do
        {:users, UserRepresentation.decode_list(items)}
      end

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    )
  end
end
