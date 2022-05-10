defmodule ControlServerWeb.Live.Kiali do
  use ControlServerWeb, :live_view

  import ControlServerWeb.IFrame
  import ControlServerWeb.Layout

  @impl true
  def render(assigns) do
    ~H"""
    <.layout container_type={:iframe}>
      <:title>
        <.title>Kiali</.title>
      </:title>
      <.iframe src={KubeResources.KialiServer.url()} />
    </.layout>
    """
  end
end
