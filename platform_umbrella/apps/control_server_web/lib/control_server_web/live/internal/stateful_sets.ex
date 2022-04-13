defmodule ControlServerWeb.Live.StatefulSets do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.StatefulSetsDisplay

  @impl true
  def mount(_params, _session, socket) do
    EventCenter.KubeState.subscribe(:stateful_sets)

    {:ok, assign(socket, :stateful_sets, stateful_sets())}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, assign(socket, :stateful_sets, stateful_sets())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :stateful_sets, stateful_sets())}
  end

  defp stateful_sets do
    KubeState.stateful_sets()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Stateful Sets</.title>
      </:title>
      <:left_menu>
        <.magic_menu active="stateful_sets" />
      </:left_menu>
      <.body_section>
        <.stateful_sets_display stateful_sets={@stateful_sets} />
      </.body_section>
    </.layout>
    """
  end
end
