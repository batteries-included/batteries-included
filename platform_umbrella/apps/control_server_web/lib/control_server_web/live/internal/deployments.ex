defmodule ControlServerWeb.Live.Deployments do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.DeploymentsDisplay

  @impl true
  def mount(_params, _session, socket) do
    EventCenter.KubeState.subscribe(:deployments)

    {:ok, assign(socket, :deployments, deployments())}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, assign(socket, :deployments, deployments())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :deployments, deployments())}
  end

  defp deployments do
    KubeState.deployments()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Deployments</.title>
      </:title>
      <:left_menu>
        <.magic_menu active="deployments" />
      </:left_menu>
      <.body_section>
        <.deployments_display deployments={@deployments} />
      </.body_section>
    </.layout>
    """
  end
end
