defmodule CommonCore.Batteries.Catalog do
  alias CommonCore.Batteries.CatalogBattery

  require Logger

  @all [
    # Data
    %CatalogBattery{
      group: :data,
      type: :redis,
      dependencies: [:battery_core],
      description:
        "Redis is an in-memory data structure store, used as a database, cache, message broker, and streaming engine."
    },
    %CatalogBattery{
      group: :data,
      type: :postgres,
      dependencies: [:battery_core],
      description:
        "PostgreSQL is a free and open-source relational database management system (RDBMS) that is known for its robustness, scalability, and extensibility."
    },
    %CatalogBattery{group: :data, type: :rook, dependencies: [:battery_core]},
    # Internal
    %CatalogBattery{group: :magic, type: :battery_core},
    %CatalogBattery{
      group: :magic,
      type: :timeline,
      dependencies: [:battery_core],
      description: "Monitor what's happened on Kubernetes and store that for later investigation."
    },
    # Devtools
    %CatalogBattery{
      group: :devtools,
      type: :knative_operator,
      dependencies: [:battery_core],
      description:
        "Knative Operator is a Kubernetes operator that provides a declarative API for managing Knative Serving and Eventing."
    },
    %CatalogBattery{
      group: :devtools,
      type: :knative_serving,
      dependencies: [:knative_operator, :istio_gateway],
      description:
        "Knative Serving is a Kubernetes-based, scale-to-zero, request-driven compute platform that lets you run stateless containers that are invocable via HTTP requests."
    },
    %CatalogBattery{
      group: :devtools,
      type: :gitea,
      dependencies: [:postgres, :istio_gateway, :battery_core],
      description:
        "Gitea is a self-hosted, open-source, Go-based Git repository manager with a web interface and command-line tools."
    },
    %CatalogBattery{
      group: :devtools,
      type: :harbor,
      dependencies: [:battery_core, :redis, :istio_gateway, :postgres],
      description: "Harbor is the trusted cloud native repository for Kubernetes"
    },
    %CatalogBattery{
      group: :devtools,
      type: :smtp4dev,
      dependencies: [:battery_core, :istio_gateway]
    },
    # ML
    %CatalogBattery{
      group: :ml,
      type: :notebooks,
      dependencies: [:istio_gateway]
    },

    # Monitoring
    %CatalogBattery{
      group: :monitoring,
      type: :grafana,
      dependencies: [:battery_core],
      description:
        "Grafana is an open-source, web-based analytics and monitoring platform that provides charts, graphs, and alerts for the web when connected to supported data sources."
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
    %CatalogBattery{
      group: :monitoring,
      type: :victoria_metrics,
      dependencies: [:battery_core],
      description:
        "Victoria Metrics is a fast, open source, and scalable monitoring solution and time series database."
    },
    %CatalogBattery{
      group: :monitoring,
      type: :kube_monitoring,
      dependencies: [:battery_core, :victoria_metrics, :kube_state_metrics, :node_exporter]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :loki,
      dependencies: [:battery_core, :grafana],
      description:
        "Loki is a horizontally scalable, highly available, multi-tenant log aggregation system inspired by Prometheus."
    },
    %CatalogBattery{
      group: :monitoring,
      type: :promtail,
      dependencies: [:battery_core, :loki]
    },
    #
    # Network/Security
    #

    # Network
    %CatalogBattery{
      group: :net_sec,
      type: :istio,
      dependencies: [],
      description:
        "Istio is an open-source service mesh that provides a unified way to control how microservices share data with one another."
    },
    %CatalogBattery{
      group: :net_sec,
      type: :istio_gateway,
      dependencies: [:istio],
      description:
        "Istio Ingress Gateway is a load balancer that sits at the edge of an Istio service mesh and routes traffic to services within the mesh."
    },
    %CatalogBattery{
      group: :net_sec,
      type: :kiali,
      dependencies: [:istio, :istio_gateway],
      description:
        "Kiali is an open-source observability tool for Istio that provides a unified view of your service mesh, including traffic, health, and configuration."
    },
    %CatalogBattery{
      group: :net_sec,
      type: :metallb,
      dependencies: [:istio_gateway, :battery_core],
      description:
        "MetalLB is a load balancer implementation for bare metal Kubernetes clusters, using standard routing protocols."
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
    },
    %CatalogBattery{
      group: :net_sec,
      type: :trivy_operator,
      dependencies: [:battery_core],
      description:
        "The Trivy Operator is a Kubernetes Operator that can be deployed directly inside of a Kubernetes cluster to run continuous security scans of your running resources and infrastructure."
    },
    %CatalogBattery{
      group: :net_sec,
      type: :sso,
      dependencies: [:battery_core, :postgres]
    }
  ]

  def all, do: @all

  def all(group) do
    Enum.filter(@all, &(&1.group == group))
  end

  def get(type) when is_binary(type) do
    get(String.to_existing_atom(type))
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
