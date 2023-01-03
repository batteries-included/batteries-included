defmodule KubeExt.Defaults.Catalog do
  alias KubeExt.Defaults.CatalogBattery
  alias KubeExt.Defaults.Namespaces
  alias KubeExt.Defaults.Images
  alias KubeExt.Defaults

  require Logger

  @all [
    # Data
    %CatalogBattery{group: :data, type: :data, dependencies: []},
    %CatalogBattery{group: :data, type: :redis_operator, dependencies: [:battery_core]},
    %CatalogBattery{group: :data, type: :redis, dependencies: [:data, :redis_operator]},
    %CatalogBattery{
      group: :data,
      type: :postgres_operator,
      dependencies: [:battery_core]
    },
    %CatalogBattery{
      group: :data,
      type: :database_public,
      dependencies: [:postgres_operator, :data]
    },
    %CatalogBattery{
      group: :data,
      type: :database_internal,
      dependencies: [:postgres_operator, :battery_core]
    },
    %CatalogBattery{group: :data, type: :rook, dependencies: [:data]},
    # Internal
    %CatalogBattery{group: :magic, type: :battery_core},
    %CatalogBattery{
      group: :magic,
      type: :control_server,
      dependencies: [:battery_core, :istio_gateway]
    },
    # Devtools
    %CatalogBattery{group: :devtools, type: :knative_operator, dependencies: [:battery_core]},
    %CatalogBattery{
      group: :devtools,
      type: :knative_serving,
      dependencies: [:knative_operator, :istio_gateway]
    },
    %CatalogBattery{
      group: :devtools,
      type: :gitea,
      dependencies: [:database_internal, :istio_gateway, :battery_core]
    },
    %CatalogBattery{
      group: :devtools,
      type: :harbor,
      dependencies: [:battery_core, :redis, :istio_gateway, :database_internal]
    },
    # ML
    %CatalogBattery{group: :ml, type: :ml_core},
    %CatalogBattery{
      group: :ml,
      type: :notebooks,
      dependencies: [:ml_core, :istio_gateway]
    },

    # Monitoring

    #
    # Network/Security
    #

    # Network
    %CatalogBattery{
      group: :net_sec,
      type: :istio,
      dependencies: []
    },
    %CatalogBattery{
      group: :net_sec,
      type: :istio_gateway,
      dependencies: [:istio]
    },
    %CatalogBattery{
      group: :net_sec,
      type: :kiali,
      dependencies: [:istio, :istio_gateway]
    },
    %CatalogBattery{
      group: :net_sec,
      type: :metallb,
      dependencies: [:istio_gateway, :battery_core]
    },
    %CatalogBattery{
      group: :net_sec,
      type: :metallb_ip_pool,
      dependencies: [:metallb]
    },
    # Security
    %CatalogBattery{
      group: :net_sec,
      type: :cert_manager,
      dependencies: [:battery_core]
    },
    %CatalogBattery{
      group: :net_sec,
      type: :battery_ca,
      dependencies: [:cert_manager]
    },
    %CatalogBattery{
      group: :net_sec,
      type: :trust_manager,
      dependencies: [:battery_core, :battery_ca, :cert_manager]
    },
    %CatalogBattery{
      group: :net_sec,
      type: :istio_csr,
      dependencies: [:istio, :battery_ca]
    }
  ]

  def all, do: Enum.map(@all, &add_config/1)

  def all(group) do
    @all
    |> Enum.filter(&(&1.group == group))
    |> Enum.map(&add_config/1)
  end

  def get(type) do
    @all
    |> Enum.find(nil, &(&1.type == type))
    |> then(fn
      nil ->
        nil

      %{} = catalog_battery ->
        add_config(catalog_battery)
    end)
  end

  def battery_type_map do
    @all
    |> Enum.map(fn bat ->
      final_bat = add_config(bat)
      {final_bat.type, final_bat}
    end)
    |> Map.new()
  end

  defp add_config(catalog_battery),
    do: %{catalog_battery | config: default_config(catalog_battery.type)}

  defp default_config(:battery_core = type),
    do: %{__type__: type, core_namespace: Namespaces.core(), base_namespace: Namespaces.base()}

  defp default_config(:data = type), do: %{__type__: type, namespace: Namespaces.data()}

  defp default_config(:istio = type),
    do: %{__type__: type, namespace: Namespaces.istio(), pilot_image: Images.istio_pilot_image()}

  defp default_config(:ml_core = type), do: %{__type__: type, namespace: Namespaces.ml()}

  defp default_config(:metallb = type),
    do: %{
      __type__: type,
      speaker_image: Images.metallb_speaker_image(),
      controller_image: Images.metallb_controller_image()
    }

  defp default_config(:metallb_ip_pool = type),
    do: %{__type__: type}

  defp default_config(:control_server = type),
    do: %{
      __type__: type,
      image: Images.control_server_image(),
      secret_key: Defaults.random_key_string()
    }

  defp default_config(:rook = type),
    do: %{__type__: type, image: Images.ceph_image()}

  defp default_config(:redis_operator = type),
    do: %{__type__: type, image: Images.redis_operator_image()}

  defp default_config(:postgres_operator = type),
    do: %{
      __type__: type,
      image: Images.postgres_operator_image(),
      spilo_image: Images.spilo_image(),
      bouncer_image: Images.postgres_bouncer_image(),
      logical_backup_image: Images.postgres_logical_backup_image(),
      json_logging_enabled: true
    }

  defp default_config(:gitea = type), do: %{__type__: type, image: Images.gitea_image()}

  defp default_config(:harbor = type),
    do: %{
      __type__: type,
      core_image: Images.harbor_core_image(),
      ctl_image: Images.harbor_ctl_image(),
      jobservice_image: Images.harbor_jobservice_image(),
      photon_image: Images.harbor_photon_image(),
      portal_image: Images.harbor_portal_image(),
      trivy_adapter_image: Images.harbor_trivy_adapter_image(),
      exporter_image: Images.harbor_exporter_image(),
      csrf_key: Defaults.random_key_string(32),
      harbor_admin_password: Defaults.random_key_string(16),
      secret: Defaults.random_key_string(),
      registry_credential_password: Defaults.random_key_string()
    }

  defp default_config(:knative_operator = type),
    do: %{
      __type__: type,
      operator_image: Images.knative_operator_image(),
      webhook_image: Images.knative_operator_webhook_image()
    }

  defp default_config(:knative_serving = type),
    do: %{__type__: type, namespace: Namespaces.knative()}

  defp default_config(:kiali = type),
    do: %{
      __type__: type,
      operator_image: Images.kiali_operator_image(),
      version: Defaults.Monitoring.kiali_version()
    }

  defp default_config(type), do: %{__type__: type}
end
