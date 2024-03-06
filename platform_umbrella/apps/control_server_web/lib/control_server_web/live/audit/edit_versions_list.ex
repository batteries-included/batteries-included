defmodule ControlServerWeb.Live.EditVersionsList do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Audit.EditVersionsTable

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_edit_versions() |> assign_page_title()}
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "Edit Versions")
  end

  def assign_edit_versions(socket) do
    assign(socket, :edit_versions, ControlServer.Audit.list_edit_versions())
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/magic"} />
    <.panel title="All Edit Versions">
      <.edit_versions_table edit_versions={@edit_versions} />
    </.panel>
    """
  end
end
