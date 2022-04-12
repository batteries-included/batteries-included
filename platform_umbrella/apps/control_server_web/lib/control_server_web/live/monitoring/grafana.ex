defmodule ControlServerWeb.Live.Grafana do
  use ControlServerWeb, :live_view

  import ControlServerWeb.IFrame
  import ControlServerWeb.Layout

  @impl true
  def render(assigns) do
    ~H"""
    <.layout container_type={:iframe}>
      <:title>
        <.title>Grafana</.title>
      </:title>
      <.iframe src={KubeResources.Grafana.url()} />
    </.layout>
    """
  end
end
