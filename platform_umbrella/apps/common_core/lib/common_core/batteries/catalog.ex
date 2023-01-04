defmodule CommonCore.Batteries.Catalog do
  alias CommonCore.Batteries.CatalogBattery

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
    %CatalogBattery{
      group: :monitoring,
      type: :grafana,
      dependencies: [:battery_core]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :kube_state_metrics,
      dependencies: [:battery_core]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :node_exporter,
      dependencies: [:battery_core]
    },
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

  def all, do: @all

  def all(group) do
    Enum.filter(@all, &(&1.group == group))
  end

  def get(type) when is_atom(type) do
    Enum.find(@all, nil, &(&1.type == type))
  end

  def get_recursive(%CatalogBattery{dependencies: deps} = catalog_battery) do
    (deps || [])
    |> Enum.flat_map(fn dep_type ->
      dep_type |> get() |> get_recursive()
    end)
    |> Enum.concat([catalog_battery])
    |> Enum.uniq_by(& &1.type)
  end

  def battery_type_map do
    @all
    |> Enum.map(fn bat ->
      {bat.type, bat}
    end)
    |> Map.new()
  end
end
