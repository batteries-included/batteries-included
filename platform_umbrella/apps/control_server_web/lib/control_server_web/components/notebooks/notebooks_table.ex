defmodule ControlServerWeb.NotebooksTable do
  @moduledoc false
  use ControlServerWeb, :html

  import KubeServices.SystemState.SummaryHosts

  attr :rows, :list, default: []
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def notebooks_table(assigns) do
    ~H"""
    <.table id="notebook-display-table" rows={@rows}>
      <:col :let={notebook} :if={!@abbridged} label="ID"><%= notebook.id %></:col>
      <:col :let={notebook} label="Name"><%= notebook.name %></:col>
      <:col :let={notebook} label="Image"><%= notebook.image %></:col>
      <:action :let={notebook}>
        <.flex>
          <.a variant="external" href={notebook_path(notebook)}>
            Open
          </.a>

          <.button
            :if={!@abbridged}
            variant="minimal"
            icon={:trash}
            id={"delete_notebook_" <> notebook.id}
            data-confirm={"Are you sure you want to delete the \"#{notebook.name}\" notebook?"}
            phx-click="delete_notebook"
            phx-value-id={notebook.id}
          />

          <.tooltip target_id={"delete_notebook_" <> notebook.id}>
            Delete Notebook
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  defp notebook_path(notebook), do: "//#{notebooks_host()}/#{notebook.name}"
end
