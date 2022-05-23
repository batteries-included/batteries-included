defmodule ControlServerWeb.Live.ServiceSettings do
  @moduledoc """
  Live web app for database stored json configs.
  """

  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.RunnableServiceList

  alias ControlServer.Services.RunnableService
  alias ControlServer.Services

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    EventCenter.Database.subscribe(:base_service)

    {:ok, socket |> assign_prefix() |> assign_services()}
  end

  @impl true
  def handle_info({_event_type, %Services.BaseService{} = _bs}, socket) do
    {:noreply, socket |> assign_prefix() |> assign_services()}
  end

  @impl true
  def handle_event("start", %{"service-type" => service_type, "value" => _}, socket) do
    RunnableService.activate!(service_type)
    {:noreply, socket}
  end

  def assign_prefix(socket),
    do: Phoenix.LiveView.assign(socket, prefix: prefix(socket.assigns.live_action))

  def assign_services(socket) do
    runnable_services = RunnableService.prefix(socket.assigns.prefix)
    service_types = Enum.map(runnable_services, fn rs -> rs.service_type end)
    base_services = Services.from_service_types(service_types)

    Phoenix.LiveView.assign(socket,
      runnable_services: runnable_services,
      base_services: base_services
    )
  end

  def prefix(live_action), do: "/#{Atom.to_string(live_action)}"

  defp action_title(%{live_action: :ml} = assigns) do
    ~H"""
    <.title>Machine Learning Settings</.title>
    """
  end

  defp action_title(assigns) do
    assigns =
      assign_new(assigns, :string_title, fn ->
        assigns
        |> Map.get(:live_action)
        |> Atom.to_string()
        |> String.capitalize()
      end)

    ~H"""
    <.title><%= @string_title %> Settings</.title>
    """
  end

  defp action_menu(%{live_action: :monitoring} = assigns) do
    ~H"""
    <.monitoring_menu active="settings" base_services={@base_services} />
    """
  end

  defp action_menu(%{live_action: :data} = assigns) do
    ~H"""
    <.data_menu active="settings" />
    """
  end

  defp action_menu(%{live_action: :devtools} = assigns) do
    ~H"""
    <.devtools_menu active="settings" base_services={@base_services} />
    """
  end

  defp action_menu(%{live_action: :network} = assigns) do
    ~H"""
    <.network_menu active="settings" base_services={@base_services} />
    """
  end

  defp action_menu(%{live_action: :security} = assigns) do
    ~H"""
    <.security_menu active="settings" />
    """
  end

  defp action_menu(%{live_action: :ml} = assigns) do
    ~H"""
    <.ml_menu active="settings" />
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.action_title live_action={@live_action} />
      </:title>
      <:left_menu>
        <.action_menu live_action={@live_action} base_services={@base_services} />
      </:left_menu>
      <.body_section>
        <.services_table runnable_services={@runnable_services} base_services={@base_services} />
      </.body_section>
    </.layout>
    """
  end
end
