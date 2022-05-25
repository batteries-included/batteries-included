defmodule ControlServerWeb.Live.Iframe do
  use ControlServerWeb, :live_view

  import ControlServerWeb.IFrame
  import ControlServerWeb.Layout

  def iframe_title(%{live_action: :alert_manager} = assigns) do
    ~H"""
    <.title>AlertManager</.title>
    """
  end

  def iframe_title(%{live_action: :grafana} = assigns) do
    ~H"""
    <.title>Grafana</.title>
    """
  end

  def iframe_title(%{live_action: :prometheus} = assigns) do
    ~H"""
    <.title>Prometheus</.title>
    """
  end

  def iframe_title(%{live_action: :gitea} = assigns) do
    ~H"""
    <.title>Gitea</.title>
    """
  end

  def iframe_url(:alert_manager), do: KubeResources.AlertManager.url()
  def iframe_url(:grafana), do: KubeResources.Grafana.url()
  def iframe_url(:prometheus), do: KubeResources.Prometheus.url()

  def iframe_url(:gitea), do: KubeResources.Gitea.url()

  def iframe_url(:kiali), do: KubeResources.KialiServer.url()

  @impl true
  def render(assigns) do
    ~H"""
    <.layout container_type={:iframe}>
      <:title>
        <.iframe_title live_action={@live_action} />
      </:title>
      <.iframe src={iframe_url(@live_action)} />
    </.layout>
    """
  end
end
