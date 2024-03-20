defmodule ControlServerWeb.Live.MLHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.EmptyHome
  import ControlServerWeb.NotebooksTable
  import KubeServices.SystemState.SummaryBatteries
  import KubeServices.SystemState.SummaryHosts
  import KubeServices.SystemState.SummaryRecent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_batteries()
     |> assign_notebooks()
     |> assign_current_page()}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: installed_batteries(:ml))
  end

  defp assign_notebooks(socket) do
    assign(socket, notebooks: notebooks())
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :ml)
  end

  defp notebooks_panel(assigns) do
    ~H"""
    <.panel title="Notebooks">
      <:menu>
        <.flex>
          <.a navigate={~p"/notebooks"}>View All</.a>
        </.flex>
      </:menu>

      <.notebooks_table rows={@notebooks} abbridged />
    </.panel>
    """
  end

  defp battery_link_panel(%{battery: %{type: :text_generation_webui}} = assigns) do
    ~H"""
    <.panel>
      <.a href={"//#{text_generation_webui_host()}/"} variant="external">Text Generation WebUI</.a>
    </.panel>
    """
  end

  defp battery_link_panel(assigns), do: ~H||

  defp install_path, do: ~p"/batteries/ml"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Machine Learning">
      <.button variant="secondary" link={install_path()}>
        Manage Batteries
      </.button>
    </.page_header>
    <.grid columns={%{sm: 1, lg: 2}} class="w-full">
      <%= for battery <- @batteries do %>
        <%= case battery.type do %>
          <% :notebooks -> %>
            <.notebooks_panel notebooks={@notebooks} />
          <% _ -> %>
        <% end %>
      <% end %>

      <.flex :if={@batteries && @batteries != []} column class="items-stretch justify-start">
        <.battery_link_panel :for={battery <- @batteries} battery={battery} />
      </.flex>
    </.grid>
    <.empty_home :if={@batteries == []} install_path={install_path()} />
    """
  end
end
