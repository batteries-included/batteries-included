defmodule ControlServerWeb.Live.Nodes do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.NodesDisplay

  @impl true
  def mount(_params, _session, socket) do
    EventCenter.KubeState.subscribe(:nodes)

    {:ok, assign(socket, :nodes, nodes())}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, assign(socket, :nodes, nodes())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :nodes, nodes())}
  end

  defp nodes do
    KubeState.nodes()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Nodes</.title>
      </:title>
      <:left_menu>
        <.magic_menu active="nodes" />
      </:left_menu>
      <.body_section>
        <.nodes_display nodes={@nodes} />
      </.body_section>
    </.layout>
    """
  end
end
