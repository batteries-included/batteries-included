defmodule ControlServerWeb.Live.Alertmanager do
  use ControlServerWeb, :live_view

  import ControlServerWeb.IFrame
  import ControlServerWeb.Layout

  @impl true
  def render(assigns) do
    ~H"""
    <.layout container_type={:iframe}>
      <:title>
        <.title>AlertManager</.title>
      </:title>
      <.iframe src={KubeResources.AlertManager.url()} />
    </.layout>
    """
  end
end
