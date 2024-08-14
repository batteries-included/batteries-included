defmodule CommonCore.Installs.TraditionalServices do
  @moduledoc false
  alias CommonCore.Defaults
  alias CommonCore.Defaults.Images
  alias CommonCore.TraditionalServices.Service

  @name "home-base"

  def name, do: @name

  def services(%{usage: :internal_prod} = installation) do
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
            mounts: [%{volume_name: "empty", mount_path: "/etc/init-config/"}]
          }
        ],
        containers: [%{name: @name, image: Images.home_base_image()}],
        ports: [%{name: "http", number: 4000, protocol: :http2}],
        volumes: [%{name: "empty", type: :empty_dir, config: %{type: :empty_dir}}],
        env_values: env()
      })
    ]
  end

  def services(%{usage: _} = _installation), do: []

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
