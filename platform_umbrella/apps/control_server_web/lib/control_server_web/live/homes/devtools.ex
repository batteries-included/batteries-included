defmodule ControlServerWeb.Live.DevtoolsHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.KnativeServicesTable
  import KubeServices.SystemState.SummaryBatteries
  import KubeServices.SystemState.SummaryHosts
  import KubeServices.SystemState.SummaryRecent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_batteries() |> assign_knative_services()}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: installed_batteries())
  end

  defp assign_knative_services(socket) do
    assign(socket, knative_services: knative_services())
  end

  defp knative_serving_panel(assigns) do
    ~H"""
    <.panel>
      <:title>Knative Services</:title>
      <:top_right>
        <.flex>
          <.a navigate={~p"/knative/services"}>View All</.a>
        </.flex>
      </:top_right>
      <.knative_services_table rows={@services} abbridged />
    </.panel>
    """
  end

  defp battery_link_panel(%{battery: %{type: :gitea}} = assigns) do
    ~H"""
    <.panel>
      <.a href={"//#{gitea_host()}/explore/repos"} variant="external">
        Gitea
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

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Devtools">
      <:right_side>
        <PC.button
          label="Manage Batteries"
          color="light"
          to={~p"/batteries/devtools"}
          link_type="live_redirect"
        />
      </:right_side>
    </.page_header>
    <.grid columns={%{sm: 1, lg: 2}} class="w-full">
      <%= for battery <- @batteries do %>
        <%= case battery.type do %>
          <% :knative_serving -> %>
            <.knative_serving_panel services={@knative_services} />
          <% _ -> %>
        <% end %>
      <% end %>
      <.flex class="flex-col items-stretch justify-start">
        <.battery_link_panel :for={battery <- @batteries} battery={battery} />
      </.flex>
    </.grid>
    """
  end
end
