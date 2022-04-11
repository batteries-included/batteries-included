defmodule ControlServerWeb.Live.DevtoolsTools do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Dev Tools</.title>
      </:title>
      <:left_menu>
        <.devtools_menu active="tools" />
      </:left_menu>
      <.body_section>
        <.h4>Gitea</.h4>
        <.button to="//control.172.30.0.4.sslip.io/x/gitea" variant="shadow" link_type="a">
          Open Gitea
          <Heroicons.Solid.external_link class="w-5 h-5" />
        </.button>
      </.body_section>
    </.layout>
    """
  end
end
