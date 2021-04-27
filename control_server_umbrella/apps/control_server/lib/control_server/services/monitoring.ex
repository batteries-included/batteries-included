defmodule ControlServer.Services.Monitoring do
  @moduledoc """

  This is the entry way into our monitoing system. This will
  be in charge of the db side and generate all the needed
  k8s configs.
  """

  @monitoring_default_path "/monitoring/base"
  @default_config %{}

  alias ControlServer.Repo
  alias ControlServer.Services.BaseService
  alias ControlServer.Services.Grafana
  alias ControlServer.Services.MonitoringSettings
  alias ControlServer.Services.Prometheus
  alias ControlServer.Services.PrometheusOperator

  import Ecto.Query, only: [from: 2]

  def activate do
    set_or_update_active(true, @monitoring_default_path)
  end

  def deactivate do
    set_or_update_active(false, @monitoring_default_path)
  end

  defp set_or_update_active(active, path) do
    query =
      from(bs in BaseService,
        where: bs.root_path == ^path
      )

    changes = %{is_active: active}

    case(Repo.one(query)) do
      # Not found create a new one
      nil ->
        %BaseService{
          is_active: active,
          root_path: path,
          service_type: :monitoring,
          config: @default_config
        }

      base_service ->
        base_service
    end
    |> BaseService.changeset(changes)
    |> Repo.insert_or_update()
  end

  def active? do
    true ==
      Repo.one(
        from(bs in BaseService,
          where: bs.root_path == ^@monitoring_default_path,
          select: bs.is_active
        )
      )
  end

  def materialize(%{} = config) do
    setup_defs = %{
      # The namespace Really really has to be first.
      "/00setup/namespace" => namespace(config),

      # Then the CRDS since they are needed for cluster roles.
      "/11setup/prometheus_crd" =>
        read_yaml("setup/prometheus-operator-0prometheusCustomResourceDefinition.yaml"),
      "/11setup/prometheus_rule_crd" =>
        read_yaml("setup/prometheus-operator-0prometheusruleCustomResourceDefinition.yaml"),
      "/11setup/service_monitor_crd" =>
        read_yaml("setup/prometheus-operator-0servicemonitorCustomResourceDefinition.yaml"),
      "/11setup/podmonitor_crd" =>
        read_yaml("setup/prometheus-operator-0podmonitorCustomResourceDefinition.yaml"),
      "/11setup/probe_crd" =>
        read_yaml("setup/prometheus-operator-0probeCustomResourceDefinition.yaml")
      # "11setup/thanos_ruler_crd" =>
      #   read_yaml("setup/prometheus-operator-0thanosrulerCustomResourceDefinition.yaml"),
      # "11setup/am_config_crd" =>
      #   read_yaml("setup/prometheus-operator-0alertmanagerConfigCustomResourceDefinition.yaml"),
      # "11setup/am_crd" =>
      #   read_yaml("setup/prometheus-operator-0alertmanagerCustomResourceDefinition.yaml"),
    }

    operator_defs = %{
      # for the prometheus operator account stuff
      "/22setup/operator_service_account" => PrometheusOperator.service_account(config),
      "/22setup/operator_cluster_role" => PrometheusOperator.cluster_role(config),
      # Bind them
      "/33setup/operator_cluster_role_binding" => PrometheusOperator.cluster_role_binding(config),
      # Run Something.
      "/44setup/operator_deployment" => PrometheusOperator.deployment(config),
      # Make it available.
      "/44setup/operator_service" => PrometheusOperator.service(config)
    }

    account_defs = %{
      "/55prometheus/prometheus_account" => Prometheus.service_account(config),
      "/66prometheus/prometheus_cluster_role" => Prometheus.role(:cluster, config),
      "/66prometheus/prometheus_config_role" => Prometheus.role(:config, config),
      "/77prometheus/prometheus_cluster_role_bind" => Prometheus.role_binding(:cluster, config),
      "/77prometheus/prometheus_config_role_bind" => Prometheus.role_binding(:config, config)
    }

    monitored_namespaces = MonitoringSettings.prometheus_main_namespaces(config)

    main_role_defs =
      Enum.flat_map(monitored_namespaces, fn target_ns ->
        [
          {"/88prometheus/prometheus_main_role_#{target_ns}",
           Prometheus.role(:main, target_ns, config)},
          {"/88prometheus/prometheus_main_role_#{target_ns}_bind",
           Prometheus.role_binding(:main, target_ns, config)}
        ]
      end)
      |> Map.new()

    main_defs = %{
      "/99prometheus/prometheus_prometheus" => Prometheus.prometheus(config),
      "/99grafana/0/service_account" => Grafana.service_account(config),
      "/99grafana/0/prometheus_datasource" => Grafana.prometheus_datasource_config(config),
      "/99grafana/0/prometheus_dashboard_datasource" => Grafana.dashboard_sources_config(config),
      "/99grafana/1/grafana_deployment" => Grafana.deployment(config),
      "/99grafana/1/grafana_service" => Grafana.service(config)
    }

    %{}
    |> Map.merge(setup_defs)
    |> Map.merge(operator_defs)
    |> Map.merge(account_defs)
    |> Map.merge(main_role_defs)
    |> Map.merge(main_defs)
  end

  def default_config do
    @default_config
  end

  defp namespace(config) do
    ns = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Namespace",
      "metadata" => %{
        "name" => ns
      }
    }
  end

  defp read_yaml(path) do
    base_path = Application.app_dir(:control_server, ["priv", "kube-prometheus", "manifests"])

    with {:ok, yaml_content} <- YamlElixir.read_from_file(base_path <> "/" <> path) do
      yaml_content
    end
  end
end
