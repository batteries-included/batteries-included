defmodule CommonCore.Batteries.Catalog do
  @moduledoc false

  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.Batteries.CatalogGroup

  @groups [
    %CatalogGroup{
      id: :data,
      name: "Datastores",
      show_for_projects: true
    },
    %CatalogGroup{
      id: :magic,
      name: "Magic",
      show_for_projects: false
    },
    %CatalogGroup{
      id: :devtools,
      name: "Devtools",
      show_for_projects: false
    },
    %CatalogGroup{
      id: :ml,
      name: "Machine Learning",
      show_for_projects: true
    },
    %CatalogGroup{
      id: :monitoring,
      name: "Monitoring",
      show_for_projects: true
    },
    %CatalogGroup{
      id: :net_sec,
      name: "Net/Security",
      show_for_projects: false
    }
  ]

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
      type: :cloudnative_pg,
      dependencies: [:battery_core],
      description:
        "PostgreSQL is a free and open-source relational database management system (RDBMS) that is known for its robustness, scalability, and extensibility."
    },
    %CatalogBattery{
      group: :data,
      type: :ferretdb,
      dependencies: [:battery_core, :cloudnative_pg],
      description: "A truly Open Source MongoDB alternative, built on Postgres"
    },
    # Magic
    %CatalogBattery{group: :magic, type: :battery_core},
    %CatalogBattery{
      group: :magic,
      type: :timeline,
      dependencies: [:battery_core],
      description: "Monitor what's happened on Kubernetes and store that for later investigation."
    },
    %CatalogBattery{
      group: :magic,
      type: :stale_resource_cleaner,
      dependencies: [:battery_core],
      description: "A battery that removes old resources that are no longer needed."
    },
    %CatalogBattery{
      group: :magic,
      type: :karpenter,
      dependencies: [:battery_core],
      description: "Auto scale kubernetes clusters in AWS EKS."
    },
    %CatalogBattery{
      group: :magic,
      type: :aws_load_balancer_controller,
      dependencies: [:battery_core, :karpenter, :battery_ca],
      description: "A Kubernetes controller for Elastic Load Balancers."
    },
    # Devtools
    %CatalogBattery{
      group: :devtools,
      type: :knative,
      dependencies: [:battery_core],
      description:
        "Knative Kubernetes operator that provides a declarative API for managing Knative Serving and Eventing. " <>
          "Knative serving is ascale-to-zero, request-driven compute platform that lets you run stateless containers " <>
          "that are invocable via HTTP requests."
    },
    %CatalogBattery{
      group: :devtools,
      type: :backend_services,
      dependencies: [:battery_core],
      description:
        "Run containers that don't conform the the serverless http model. " <>
          "This is useful for running long running processes, or for running services that need to be accessed by other services."
    },
    %CatalogBattery{
      group: :devtools,
      type: :forgejo,
      dependencies: [:cloudnative_pg, :istio_gateway, :battery_core],
      description:
        "Forgejo is a self-hosted, open-source, Go-based Git repository manager with a web interface and command-line tools."
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
    %CatalogBattery{
      group: :ml,
      type: :text_generation_webui,
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
      type: :vm_operator,
      dependencies: [:battery_core]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :vm_agent,
      dependencies: [:vm_operator]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :vm_cluster,
      dependencies: [:vm_operator]
    },
    %CatalogBattery{
      group: :monitoring,
      type: :victoria_metrics,
      dependencies: [:battery_core, :vm_operator, :vm_agent, :vm_cluster],
      description: "Victoria Metrics is a fast, open source, and scalable monitoring solution and time series database."
    },
    %CatalogBattery{
      group: :monitoring,
      type: :kube_monitoring,
      description: "All of the systems needed to monitor Kubernetes with VictoriaMetrics.",
      dependencies: [:battery_core, :victoria_metrics]
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
      dependencies: [:istio, :istio_gateway, :grafana, :victoria_metrics],
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
      type: :keycloak,
      dependencies: [:battery_core, :cloudnative_pg],
      description: "Open Source Identity and Access Management For Modern Applications and Services"
    },
    %CatalogBattery{
      group: :net_sec,
      type: :sso,
      dependencies: [:battery_core, :keycloak]
    }
  ]

  def groups, do: @groups

  def groups_for_projects do
    Enum.filter(@groups, & &1.show_for_projects)
  end

  def group(id) when is_binary(id) do
    group(String.to_existing_atom(id))
  end

  def group(id) do
    Enum.find(@groups, &(&1.id == id))
  end

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

  def get_recursive(catalog_battery) when is_atom(catalog_battery) do
    catalog_battery |> get() |> get_recursive()
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
    Map.new(@all, fn bat -> {bat.type, bat} end)
  end
end
