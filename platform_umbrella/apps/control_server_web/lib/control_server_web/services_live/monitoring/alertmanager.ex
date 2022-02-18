defmodule ControlServerWeb.ServicesLive.Alertmanager do
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
      <.iframe src="/x/alertmanager" />
    </.layout>
    """
  end
end
