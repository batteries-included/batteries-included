defmodule CommonCore.Installs.TraditionalServices do
  @moduledoc false
  alias CommonCore.Defaults
  alias CommonCore.Defaults.Images
  alias CommonCore.TraditionalServices.Service

  @home_base_name "home-base"
  @cla_name "cla"
  @jwk_secret "home-base-jwk"

  def home_base_name, do: @home_base_name
  def cla_name, do: @cla_name

  def services(%{usage: usage} = installation) when usage in [:internal_int_test, :internal_prod] do
    Enum.map([&home_base/1, &cla/1], fn func -> func.(installation) end)
  end

  def services(%{usage: _} = _installation), do: []

  defp home_base(installation) do
    Service.new!(%{
      additional_hosts: ["home.batteriesincl.com"],
      name: @home_base_name,
      virtual_size: install_size(installation),
      init_containers: [
        %{
          name: "init",
          image: Images.home_base_image(),
          command: ["/app/bin/start"],
          args: ["home_base_init"],
          mounts: [%{volume_name: "home-base-seed-data", mount_path: "/etc/init-config/", read_only: true}]
        }
      ],
      containers: [%{name: @home_base_name, image: Images.home_base_image()}],
      ports: [%{name: @home_base_name, number: 4000, protocol: :http2}],
      volumes: [
        # This is populated during generation from home-base-init-data
        %{
          name: "home-base-seed-data",
          type: :config_map,
          config: %{type: :config_map, name: "home-base-seed-data", optional: true}
        },
        # This will need to be manually created
        %{
          name: @jwk_secret,
          type: :secret,
          config: %{type: :secret, name: @jwk_secret, optional: false}
        }
      ],
      env_values: home_base_env()
    })
  end

  defp cla(installation) do
    Service.new!(%{
      additional_hosts: ["#{@cla_name}.batteriesincl.com"],
      name: @cla_name,
      virtual_size: install_size(installation),
      init_containers: [],
      containers: [%{name: @cla_name, image: "ghcr.io/batteries-included/cla-assistant:v2.13.1"}],
      ports: [%{name: @cla_name, number: 5000, protocol: :http2}],
      volumes: [],
      env_values: cla_env()
    })
  end

  defp install_size(%{usage: :internal_int_test} = _install), do: "small"

  # The install sizes and service sizes match up but they may? not always
  defp install_size(install), do: Atom.to_string(install.default_size)

  defp home_base_env do
    pg_secret = "cloudnative-pg.pg-#{@home_base_name}.#{@home_base_name}"

    [
      %{
        name: "SECRET_KEY_BASE",
        value: Defaults.random_key_string(),
        source_type: "value"
      },
      %{
        name: "HOME_JWK",
        source_type: "secret",
        source_name: @jwk_secret,
        source_key: "jwk"
      },
      %{
        name: "POSTGRES_DB",
        value: @home_base_name,
        source_type: "value"
      },
      %{
        name: "POSTGRES_USER",
        source_type: "secret",
        source_name: pg_secret,
        source_key: "username"
      },
      %{
        name: "POSTGRES_PASSWORD",
        source_type: "secret",
        source_name: pg_secret,
        source_key: "password"
      },
      %{
        name: "POSTGRES_HOST",
        source_type: "secret",
        source_name: pg_secret,
        source_key: "hostname"
      }
    ]
  end

  defp cla_env do
    [
      %{
        name: "PROTOCOL",
        value: "https",
        source_type: "value"
      },
      %{
        name: "HOST",
        value: "#{@cla_name}.batteriesincl.com",
        source_type: "value"
      },
      %{
        name: "NODE_ENV",
        value: "prod",
        source_type: "value"
      },
      # This ferret instance needs to be created manually / add ferret bootstrap capabilities
      %{
        name: "MONGODB",
        source_type: "secret",
        source_name: "ferret.#{@cla_name}.#{@cla_name}",
        source_key: "uri"
      }
    ] ++
      Enum.map(
        # These values need to be in a secret that is manually created
        ~w(TOKEN SECRET CLIENT APP_SECRET APP_PRIVATE_KEY APP_NAME APP_ID APP_CLIENT APP_SECRET ADMIN_USERS),
        fn var ->
          %{
            name: "GITHUB_#{var}",
            source_type: "secret",
            source_name: @cla_name,
            source_key: "GITHUB_#{var}"
          }
        end
      )
  end
end
