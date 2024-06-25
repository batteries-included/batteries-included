defmodule ControlServerWeb.Live.DevtoolsHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.BackendServicesTable
  import ControlServerWeb.EmptyHome
  import ControlServerWeb.KnativeServicesTable
  import KubeServices.SystemState.SummaryBatteries
  import KubeServices.SystemState.SummaryHosts
  import KubeServices.SystemState.SummaryRecent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_batteries()
     |> assign_knative_services()
     |> assign_backend_services()
     |> assign_current_page()}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: installed_batteries(:devtools))
  end

  defp assign_knative_services(socket) do
    assign(socket, knative_services: knative_services())
  end

  defp assign_backend_services(socket) do
    assign(socket, backend_services: backend_services())
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :devtools)
  end

  defp knative_panel(assigns) do
    ~H"""
    <.panel title="Serverless Services">
      <:menu>
        <.flex>
          <.a navigate={~p"/knative/services/new"}>
            <.icon name={:plus} class="inline-flex h-5 w-auto my-auto" /> New Knative
          </.a>
          <.link navigate={~p"/knative/services"}>View All</.link>
        </.flex>
      </:menu>
      <.knative_services_table rows={@services} abbridged />
    </.panel>
    """
  end

  defp backend_services_panel(assigns) do
    ~H"""
    <.panel title="Backend Services">
      <:menu>
        <.flex>
          <.a navigate={~p"/backend_services/new"}>
            <.icon name={:plus} class="inline-flex h-5 w-auto my-auto" /> New Backend Service
          </.a>
          <.link navigate={~p"/backend_services/"}>View All</.link>
        </.flex>
      </:menu>
      <.backend_services_table rows={@services} abbridged />
    </.panel>
    """
  end

  defp battery_link_panel(%{battery: %{type: :forgejo}} = assigns) do
    ~H"""
    <.panel>
      <.a href={"//#{forgejo_host()}/explore/repos"} variant="external">
        Forgejo
      </.a>
    </.panel>
    """
  end

  defp battery_link_panel(%{battery: %{type: :smtp4dev}} = assigns) do
    ~H"""
    <.panel>
      <.a href={"//#{smtp4dev_host()}"} variant="external">SMTP4Dev</.a>
    </.panel>
    """
  end

  defp battery_link_panel(assigns), do: ~H||

  defp install_path, do: ~p"/batteries/devtools"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Devtools">
      <.button variant="secondary" icon={:kubernetes} link={install_path()}>
        Manage Batteries
      </.button>
    </.page_header>
    <.grid :if={@batteries && @batteries != []} columns={%{sm: 1, lg: 2}} class="w-full">
      <%= for battery <- @batteries do %>
        <%= case battery.type do %>
          <% :knative -> %>
            <.knative_panel services={@knative_services} />
          <% :backend_services -> %>
            <.backend_services_panel services={@backend_services} />
          <% _ -> %>
        <% end %>
      <% end %>
      <.flex column class="items-stretch justify-start">
        <.battery_link_panel :for={battery <- @batteries} battery={battery} />
      </.flex>
    </.grid>

    <.empty_home :if={@batteries == []} install_path={install_path()}>
      <:header>
        <.h2>Batteries Included Devtools</.h2>
      </:header>
    </.empty_home>
    """
  end
end
