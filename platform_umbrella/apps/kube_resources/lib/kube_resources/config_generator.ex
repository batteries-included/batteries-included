defmodule KubeResources.ConfigGenerator do
  @moduledoc """
  Given any BaseService this will extract the kubernetes configs for application to the cluster.
  """

  alias ControlServer.Services.BaseService

  alias KubeRawResources.Battery
  alias KubeRawResources.IstioBase
  alias KubeRawResources.IstioIstiod

  alias KubeResources.AlertManager
  alias KubeResources.CertManager
  alias KubeResources.ControlServerResources
  alias KubeResources.Database
  alias KubeResources.EchoServer
  alias KubeResources.Gitea
  alias KubeResources.GithubActionsRunner
  alias KubeResources.Grafana
  alias KubeResources.IstioGateway
  alias KubeResources.Keycloak
  alias KubeResources.KnativeOperator
  alias KubeResources.KnativeServices
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

  @spec materialize(map, atom) :: map
  def materialize(%{} = config, :prometheus) do
    config |> Prometheus.materialize() |> Map.merge(ServiceMonitors.materialize(config))
  end

  def materialize(%{} = config, :istio_gateway) do
    config |> IstioGateway.materialize() |> Map.merge(VirtualService.materialize(config))
  end

  def materialize(%{} = config, :knative) do
    config
    |> KnativeOperator.materialize()
    |> Map.merge(KnativeServices.materialize(config))
  end

  def materialize(%{} = config, :prometheus_operator), do: PrometheusOperator.materialize(config)
  def materialize(%{} = config, :grafana), do: Grafana.materialize(config)
  def materialize(%{} = config, :alert_manager), do: AlertManager.materialize(config)
  def materialize(%{} = config, :kube_monitoring), do: KubeMonitoring.materialize(config)

  def materialize(%{} = config, :database), do: Database.materialize_common(config)
  def materialize(%{} = config, :database_public), do: Database.materialize_public(config)
  def materialize(%{} = config, :database_internal), do: Database.materialize_internal(config)

  def materialize(%{} = config, :cert_manager), do: CertManager.materialize(config)
  def materialize(%{} = config, :keycloak), do: Keycloak.materialize(config)

  def materialize(%{} = config, :gitea), do: Gitea.materialize(config)
  def materialize(%{} = config, :github_runner), do: GithubActionsRunner.materialize(config)

  def materialize(%{} = config, :kong), do: Kong.materialize(config)
  def materialize(%{} = config, :nginx), do: Nginx.materialize(config)
  def materialize(%{} = config, :istio), do: IstioBase.materialize(config)
  def materialize(%{} = config, :istio_istiod), do: IstioIstiod.materialize(config)

  def materialize(%{} = config, :battery), do: Battery.materialize(config)
  def materialize(%{} = config, :control_server), do: ControlServerResources.materialize(config)
  def materialize(%{} = config, :echo_server), do: EchoServer.materialize(config)

  def materialize(%{} = config, :ml), do: ML.Base.materialize(config)
  def materialize(%{} = config, :notebooks), do: Notebooks.materialize(config)
end
