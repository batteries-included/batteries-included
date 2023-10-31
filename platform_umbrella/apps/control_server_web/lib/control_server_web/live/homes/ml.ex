defmodule ControlServerWeb.Live.MLHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.NotebooksTable
  import KubeServices.SystemState.SummaryBatteries
  import KubeServices.SystemState.SummaryRecent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_batteries() |> assign_notebooks()}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: installed_batteries())
  end

  defp assign_notebooks(socket) do
    assign(socket, notebooks: notebooks())
  end

  defp notebooks_panel(assigns) do
    ~H"""
    <.panel>
      <:title>Notebooks</:title>
      <:top_right>
        <.flex>
          <.a navigate={~p"/notebooks"}>View All</.a>
        </.flex>
      </:top_right>

      <.notebooks_table rows={@notebooks} abbridged />
    </.panel>
    """
  end

  defp battery_link_panel(assigns), do: ~H||

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Machine Learning">
      <:right_side>
        <PC.button
          label="Manage Batteries"
          color="light"
          to={~p"/batteries/ml"}
          link_type="live_redirect"
        />
      </:right_side>
    </.page_header>
    <.grid columns={%{sm: 1, lg: 2}} class="w-full">
      <%= for battery <- @batteries do %>
        <%= case battery.type do %>
          <% :notebooks -> %>
            <.notebooks_panel notebooks={@notebooks} />
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
