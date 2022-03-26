defmodule ControlServerWeb.Live.DevtoolsStatus do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.PodDisplay

  alias ControlServer.Services.Pods

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

    {:ok, assign(socket, :pods, pods())}
  end

  @impl true
  def handle_info(:update, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

    {:noreply, assign(socket, :pods, pods())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp pods do
    Enum.map(Pods.get("battery-knative"), &Pods.summarize/1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Knative Pods</.title>
      </:title>
      <:left_menu>
        <.devtools_menu active="status" />
      </:left_menu>
      <.body_section>
        <.pods_display pods={@pods} />
      </.body_section>
    </.layout>
    """
  end
end
