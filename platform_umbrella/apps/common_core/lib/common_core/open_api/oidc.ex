defmodule CommonCore.OpenApi.OIDC do
  @moduledoc false

  defmodule MTLSEndpointAliases do
    @moduledoc false
    use CommonCore.OpenApi.Schema

    @derive Jason.Encoder
    typed_embedded_schema do
      field :token_endpoint, :string
      field :revocation_endpoint, :string
      field :introspection_endpoint, :string
      field :device_authorization_endpoint, :string
      field :registration_endpoint, :string
      field :userinfo_endpoint, :string
      field :pushed_authorization_request_endpoint, :string
      field :backchannel_authentication_endpoint, :string
    end
  end

  defmodule OIDCConfiguration do
    @moduledoc false
    use CommonCore.OpenApi.Schema

    @derive Jason.Encoder
    typed_embedded_schema do
      field :issuer, :string

      # Endpoints
      field :authorization_endpoint, :string
      field :token_endpoint, :string
      field :introspection_endpoint, :string
      field :userinfo_endpoint, :string
      field :end_session_endpoint, :string
      field :registration_endpoint, :string
      field :device_authorization_endpoint, :string
      field :backchannel_authentication_endpoint, :string
      field :pushed_authorization_request_endpoint, :string
      field :revocation_endpoint, :string

      embeds_one :mtls_endpoint_aliases, MTLSEndpointAliases

      field :jwks_uri, :string
      field :check_session_iframe, :string

      field :revocation_endpoint_auth_methods_supported, {:array, :string}
      field :revocation_endpoint_auth_signing_alg_values_supported, {:array, :string}

      field :frontchannel_logout_session_supported, :boolean
      field :frontchannel_logout_supported, :boolean

      field :grant_types_supported, {:array, :string}
      field :acr_values_supported, {:array, :string}
      field :response_types_supported, {:array, :string}
      field :subject_types_supported, {:array, :string}

      field :id_token_signing_alg_values_supported, {:array, :string}
      field :id_token_encryption_alg_values_supported, {:array, :string}
      field :id_token_encryption_enc_values_supported, {:array, :string}

      field :userinfo_signing_alg_values_supported, {:array, :string}
      field :userinfo_encryption_alg_values_supported, {:array, :string}
      field :userinfo_encryption_enc_values_supported, {:array, :string}

      field :request_object_signing_alg_values_supported, {:array, :string}
      field :request_object_encryption_alg_values_supported, {:array, :string}
      field :request_object_encryption_enc_values_supported, {:array, :string}

      field :response_modes_supported, {:array, :string}

      field :token_endpoint_auth_methods_supported, {:array, :string}
      field :token_endpoint_auth_signing_alg_values_supported, {:array, :string}

      field :introspection_endpoint_auth_methods_supported, {:array, :string}
      field :introspection_endpoint_auth_signing_alg_values_supported, {:array, :string}

      field :authorization_signing_alg_values_supported, {:array, :string}
      field :authorization_encryption_alg_values_supported, {:array, :string}
      field :authorization_encryption_enc_values_supported, {:array, :string}

      field :claims_supported, {:array, :string}
      field :claim_types_supported, {:array, :string}
      field :claim_parameter_supported, :boolean

      field :scopes_supported, {:array, :string}

      field :request_parameter_supported, :boolean
      field :request_uri_parameter_supported, :boolean
      field :require_request_uri_registration, :boolean

      field :code_challenge_methods_supported, {:array, :string}

      field :backchannel_logout_supported, :boolean
      field :backchannel_logout_session_supported, :boolean

      field :backchannel_token_delivery_modes_supported, {:array, :string}
      field :backchannel_authentication_request_signing_alg_values_supported, {:array, :string}

      field :require_pushed_authorization_requests, :boolean
    end
  end
end
