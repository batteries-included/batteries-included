defmodule ControlServerWeb.Live.Gitea do
  use ControlServerWeb, :live_view

  import ControlServerWeb.IFrame
  import ControlServerWeb.Layout

  @impl true
  def render(assigns) do
    ~H"""
    <.layout container_type={:iframe}>
      <.iframe src={KubeResources.Gitea.url()} />
    </.layout>
    """
  end
end
