defmodule KubeResources.Ingress do
  alias ControlServer.Services
  alias KubeResources.ControlServerResources
  alias KubeResources.Grafana
  alias KubeResources.Prometheus

  require Logger

  def materialize(_config) do
    Services.all_including_config()
    |> Enum.map(fn bs -> {"/ingress/#{bs.id}", ingress(bs.service_type, bs.config)} end)
    |> Enum.into(%{})
  end

  def ingress(:prometheus, config), do: Prometheus.ingress(config)
  def ingress(:grafana, config), do: Grafana.ingress(config)
  def ingress(:control_server, config), do: ControlServerResources.ingress(config)

  def ingress(_, _config), do: []
end
