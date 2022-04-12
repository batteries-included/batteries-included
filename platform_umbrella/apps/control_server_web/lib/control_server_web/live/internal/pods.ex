defmodule ControlServerWeb.Live.Pods do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.PodsDisplay

  @impl true
  def mount(_params, _session, socket) do
    EventCenter.KubeState.subscribe(:pods)

    {:ok, assign(socket, :pods, pods())}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, assign(socket, :pods, pods())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :pods, pods())}
  end

  defp pods do
    KubeState.pods()
    |> Enum.map(&KubeExt.Pods.summarize/1)
    |> Enum.sort_by(
      fn pod ->
        pod
        |> Map.get("status", %{})
        |> Map.get("startTime", "")
      end,
      :desc
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Pods</.title>
      </:title>
      <:left_menu>
        <.magic_menu active="pods" />
      </:left_menu>
      <.body_section>
        <.pods_display pods={@pods} />
      </.body_section>
    </.layout>
    """
  end
end
