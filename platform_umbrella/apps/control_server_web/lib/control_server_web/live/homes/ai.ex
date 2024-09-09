defmodule ControlServerWeb.Live.AIHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.EmptyHome
  import ControlServerWeb.ModelInstancesTable
  import ControlServerWeb.NotebooksTable
  import KubeServices.SystemState.SummaryBatteries
  import KubeServices.SystemState.SummaryRecent

  alias CommonCore.Batteries.Catalog

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_batteries()
     |> assign_notebooks()
     |> assign_model_instances()
     |> assign_catalog_group()
     |> assign_current_page()
     |> assign_page_title()}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: installed_batteries(:ai))
  end

  defp assign_notebooks(socket) do
    assign(socket, notebooks: notebooks())
  end

  defp assign_model_instances(socket) do
    assign(socket, model_instances: model_instances())
  end

  defp assign_catalog_group(socket) do
    assign(socket, catalog_group: Catalog.group(:ai))
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: socket.assigns.catalog_group.type)
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: socket.assigns.catalog_group.name)
  end

  defp notebooks_panel(assigns) do
    ~H"""
    <.panel title="Jupyter Notebooks">
      <:menu>
        <.flex>
          <.button icon={:plus} link={~p"/notebooks/new"}>New Notebook</.button>
          <.button variant="minimal" link={~p"/notebooks"}>View All</.button>
        </.flex>
      </:menu>

      <.notebooks_table rows={@notebooks} abridged />
    </.panel>
    """
  end

  defp model_instances_panel(assigns) do
    ~H"""
    <.panel title="Ollama Models">
      <:menu>
        <.flex>
          <.button icon={:plus} link={~p"/model_instances/new"}>New Model</.button>
          <.button variant="minimal" link={~p"/model_instances"}>View All</.button>
        </.flex>
      </:menu>

      <.model_instances_table rows={@model_instances} abridged />
    </.panel>
    """
  end

  defp battery_link_panel(assigns), do: ~H||

  defp install_path, do: ~p"/batteries/ai"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title}>
      <.button variant="secondary" icon={:kubernetes} link={install_path()}>
        Manage Batteries
      </.button>
    </.page_header>
    <.grid columns={%{sm: 1, lg: 2}} class="w-full">
      <%= for battery <- @batteries do %>
        <%= case battery.type do %>
          <% :notebooks -> %>
            <.notebooks_panel notebooks={@notebooks} />
          <% :ollama -> %>
            <.model_instances_panel model_instances={@model_instances} />
          <% _ -> %>
        <% end %>
      <% end %>

      <.flex :if={@batteries && @batteries != []} column class="items-stretch justify-start">
        <.battery_link_panel :for={battery <- @batteries} battery={battery} />
      </.flex>
    </.grid>

    <.empty_home :if={@batteries == []} icon={@catalog_group.icon} install_path={install_path()} />
    """
  end
end
