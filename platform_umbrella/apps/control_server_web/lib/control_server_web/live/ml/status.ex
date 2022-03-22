defmodule ControlServerWeb.Live.MLStatus do
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

  defp pods do
    Enum.map(Pods.get("battery-ml"), &Pods.summarize/1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>ML Pods</.title>
      </:title>
      <:left_menu>
        <.left_menu_item to="/services/ml" name="Home" icon="home" />
        <.left_menu_item to="/services/ml/notebooks" name="Notebooks" icon="notebooks" />

        <.left_menu_item to="/services/ml/settings" name="Service Settings" icon="lightning_bolt" />
        <.left_menu_item to="/services/ml/status" name="Status" icon="status_online" is_active={true} />
      </:left_menu>
      <.body_section>
        <.pods_display pods={@pods} />
      </.body_section>
    </.layout>
    """
  end
end
