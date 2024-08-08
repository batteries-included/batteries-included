defmodule ControlServerWeb.Live.EditVersionsList do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Audit.EditVersionsTable

  alias ControlServer.Audit

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Edit Versions")}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {edit_versions, meta}} <- Audit.list_edit_versions(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:edit_versions, edit_versions)}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/magic"} />

    <.panel title="All Versions">
      <.edit_versions_table rows={@edit_versions} meta={@meta} />
    </.panel>
    """
  end
end
