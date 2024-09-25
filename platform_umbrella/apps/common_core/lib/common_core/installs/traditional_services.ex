defmodule CommonCore.Installs.TraditionalServices do
  @moduledoc false
  alias CommonCore.Defaults
  alias CommonCore.Defaults.Images
  alias CommonCore.TraditionalServices.Service

  @name "home-base"
  @jwk_secret "home-base-jwk"

  def name, do: @name

  def services(%{usage: usage} = installation) when usage in [:internal_int_test, :internal_prod] do
    [
      Service.new!(%{
        name: @name,
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
        containers: [%{name: @name, image: Images.home_base_image()}],
        ports: [%{name: "http", number: 4000, protocol: :http2}],
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
        env_values: env()
      })
    ]
  end

  def services(%{usage: _} = _installation), do: []

  defp install_size(%{usage: :internal_int_test} = _install), do: "small"

  # The install sizes and service sizes match up but they may? not always
  defp install_size(install), do: Atom.to_string(install.default_size)

  defp env do
    pg_secret = "cloudnative-pg.pg-#{@name}.#{@name}"

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
        value: @name,
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
end
