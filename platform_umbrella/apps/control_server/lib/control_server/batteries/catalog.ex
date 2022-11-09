defmodule ControlServer.Batteries.Catalog do
  alias ControlServer.Batteries.CatalogBattery

  @all [
    # Data
    %CatalogBattery{group: :data, type: :data, dependencies: [:battery_core]},
    %CatalogBattery{group: :data, type: :redis_operator, dependencies: [:battery_core]},
    %CatalogBattery{group: :data, type: :redis, dependencies: [:data, :redis_operator]},
    %CatalogBattery{
      group: :data,
      type: :postgres_operator,
      dependencies: [:data, :battery_core]
    },
    %CatalogBattery{
      group: :data,
      type: :database_public,
      dependencies: [:postgres_operator, :data, :battery_core]
    },
    %CatalogBattery{
      group: :data,
      type: :database_internal,
      dependencies: [:postgres_operator, :data]
    },
    %CatalogBattery{group: :data, type: :rook, dependencies: [:data]},
    %CatalogBattery{group: :data, type: :ceph, dependencies: [:data, :rook]},
    # Internal
    %CatalogBattery{group: :magic, type: :battery_core},
    %CatalogBattery{
      group: :magic,
      type: :control_server,
      dependencies: [:battery_core, :istio_gateway]
    },
    # Devtools
    %CatalogBattery{group: :devtools, type: :knative, dependencies: [:battery_core]},
    %CatalogBattery{
      group: :devtools,
      type: :knative_serving,
      dependencies: [:knative, :istio_gateway]
    },
    %CatalogBattery{
      group: :devtools,
      type: :gitea,
      dependencies: [:database_internal, :istio_gateway, :battery_core]
    },
    %CatalogBattery{group: :devtools, type: :tekton_operator, dependencies: [:battery_core]},
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
      type: :prometheus_operator,
      dependencies: [:battery_core]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :grafana,
      dependencies: [:prometheus_operator, :istio_gateway]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :alert_manager,
      dependencies: [:prometheus_operator, :istio_gateway]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :prometheus,
      dependencies: [:prometheus_operator, :istio_gateway]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :kube_state_metrics,
      dependencies: [:prometheus]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :node_exporter,
      dependencies: [:prometheus]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :monitoring_api_server,
      dependencies: [:prometheus, :grafana]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :monitoring_controller_manager,
      dependencies: [:prometheus, :grafana]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :monitoring_coredns,
      dependencies: [:prometheus, :grafana]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :monitoring_etcd,
      dependencies: [:prometheus, :grafana]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :monitoring_kube_proxy,
      dependencies: [:prometheus, :grafana]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :monitoring_kubelet,
      dependencies: [:prometheus, :grafana]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :monitoring_scheduler,
      dependencies: [:prometheus, :grafana]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :prometheus_stack,
      dependencies: [
        :battery_core,
        :prometheus_operator,
        :grafana,
        :alert_manager,
        :prometheus,
        :node_exporter,
        :kube_state_metrics,
        :monitoring_api_server,
        :monitoring_controller_manager,
        :monitoring_coredns,
        :monitoring_etcd,
        :monitoring_kube_proxy,
        :monitoring_kubelet,
        :monitoring_scheduler
      ]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :loki,
      dependencies: [:battery_core, :prometheus, :grafana, :istio_gateway]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :promtail,
      dependencies: [:loki]
    },
    # Network/Security
    %CatalogBattery{group: :net_sec, type: :istio, dependencies: [:battery_core]},
    %CatalogBattery{
      group: :net_sec,
      type: :istio_istiod,
      dependencies: [:istio, :battery_core]
    },
    %CatalogBattery{
      group: :net_sec,
      type: :istio_gateway,
      dependencies: [:istio_istiod, :istio]
    },
    %CatalogBattery{
      group: :net_sec,
      type: :kiali,
      dependencies: [:istio_istiod, :istio_gateway, :prometheus, :grafana]
    },
    %CatalogBattery{
      group: :net_sec,
      type: :metallb,
      dependencies: [:istio_istiod, :istio_gateway]
    },
    %CatalogBattery{
      group: :net_sec,
      type: :dev_metallb,
      dependencies: [:metallb]
    },
    %CatalogBattery{
      group: :net_sec,
      type: :echo_server,
      dependencies: [:istio_gateway]
    },
    # Security
    %CatalogBattery{
      group: :net_sec,
      type: :ory_hydra,
      dependencies: [:database_internal]
    }
  ]

  def all, do: @all
  def all(group), do: Enum.filter(@all, &(&1.group == group))

  def get(type), do: Enum.find(@all, &(&1.type == type))

  def battery_type_map, do: @all |> Enum.map(&{&1.type, &1}) |> Map.new()
end
