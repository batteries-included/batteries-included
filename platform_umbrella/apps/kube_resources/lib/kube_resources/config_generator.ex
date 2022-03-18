defmodule KubeResources.ConfigGenerator do
  @moduledoc """
  Given any BaseService this will extract the kubernetes configs for application to the cluster.
  """

  alias ControlServer.Services.BaseService
  alias KubeRawResources.Battery
  alias KubeRawResources.Istio
  alias KubeResources.AlertManager
  alias KubeResources.CertManager
  alias KubeResources.ControlServerResources
  alias KubeResources.Database
  alias KubeResources.EchoServer
  alias KubeResources.GithubActionsRunner
  alias KubeResources.Grafana
  alias KubeResources.Keycloak
  alias KubeResources.KnativeOperator
  alias KubeResources.Kong
  alias KubeResources.KubeMonitoring
  alias KubeResources.ML
  alias KubeResources.Nginx
  alias KubeResources.Notebooks
  alias KubeResources.Prometheus
  alias KubeResources.PrometheusOperator
  alias KubeResources.ServiceMonitors
  alias KubeResources.VirtualService

  def materialize(%BaseService{} = base_service) do
    base_service.config
    |> materialize(base_service.service_type)
    |> Enum.map(fn {key, value} -> {Path.join(base_service.root_path, key), value} end)
    |> Enum.into(%{})
  end

  defp materialize(%{} = config, :prometheus) do
    config |> Prometheus.materialize() |> Map.merge(ServiceMonitors.materialize(config))
  end

  defp materialize(%{} = config, :istio) do
    config |> Istio.materialize() |> Map.merge(VirtualService.materialize(config))
  end

  defp materialize(%{} = config, :prometheus_operator), do: PrometheusOperator.materialize(config)
  defp materialize(%{} = config, :grafana), do: Grafana.materialize(config)
  defp materialize(%{} = config, :alert_manager), do: AlertManager.materialize(config)
  defp materialize(%{} = config, :kube_monitoring), do: KubeMonitoring.materialize(config)

  defp materialize(%{} = config, :database), do: Database.materialize_common(config)
  defp materialize(%{} = config, :database_public), do: Database.materialize_public(config)
  defp materialize(%{} = config, :database_internal), do: Database.materialize_internal(config)

  defp materialize(%{} = config, :cert_manager), do: CertManager.materialize(config)
  defp materialize(%{} = config, :keycloak), do: Keycloak.materialize(config)

  defp materialize(%{} = config, :knative), do: KnativeOperator.materialize(config)
  defp materialize(%{} = config, :github_runner), do: GithubActionsRunner.materialize(config)

  defp materialize(%{} = config, :kong), do: Kong.materialize(config)
  defp materialize(%{} = config, :nginx), do: Nginx.materialize(config)

  defp materialize(%{} = config, :battery), do: Battery.materialize(config)
  defp materialize(%{} = config, :control_server), do: ControlServerResources.materialize(config)
  defp materialize(%{} = config, :echo_server), do: EchoServer.materialize(config)

  defp materialize(%{} = config, :ml), do: ML.Base.materialize(config)
  defp materialize(%{} = config, :notebooks), do: Notebooks.materialize(config)
end
