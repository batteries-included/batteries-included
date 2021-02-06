defmodule ServerWeb.RawConfigLive.Index do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ServerWeb, :live_view

  alias Server.Configs
  alias Server.Configs.RawConfig

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :raw_configs, list_raw_configs())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Raw config")
    |> assign(:raw_config, Configs.get_raw_config!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Raw config")
    |> assign(:raw_config, %RawConfig{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Raw configs")
    |> assign(:raw_config, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    raw_config = Configs.get_raw_config!(id)
    {:ok, _} = Configs.delete_raw_config(raw_config)

    {:noreply, assign(socket, :raw_configs, list_raw_configs())}
  end

  defp list_raw_configs do
    Configs.list_raw_configs()
  end
end
