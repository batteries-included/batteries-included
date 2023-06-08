defmodule ControlServerWeb.Live.EditVersionsList do
  use ControlServerWeb, {:live_view, layout: :fresh}

  import ControlServerWeb.Audit.EditVersionsTable

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign_edit_versions(socket)}
  end

  def assign_edit_versions(socket) do
    assign(socket, :edit_versions, ControlServer.Audit.list_edit_versions())
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.h1>Edit Versions</.h1>
    <.edit_versions_table edit_versions={@edit_versions} />
    """
  end
end
