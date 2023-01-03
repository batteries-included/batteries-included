defmodule ControlServerWeb.Live.Iframe do
  use ControlServerWeb, :live_view

  import ControlServerWeb.IFrame
  import ControlServerWeb.MenuLayout

  def iframe_title(%{live_action: :gitea} = assigns) do
    ~H"""
    <.title>Gitea</.title>
    """
  end

  def iframe_url(:gitea), do: KubeResources.Gitea.url()

  def iframe_url(:kiali), do: KubeResources.Kiali.url()

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.menu_layout container_type={:iframe}>
      <:title>
        <.iframe_title live_action={@live_action} />
      </:title>
      <.iframe src={iframe_url(@live_action)} />
    </.menu_layout>
    """
  end
end
