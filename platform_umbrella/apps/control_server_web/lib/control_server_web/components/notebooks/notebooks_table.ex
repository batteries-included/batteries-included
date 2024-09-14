defmodule ControlServerWeb.NotebooksTable do
  @moduledoc false
  use ControlServerWeb, :html

  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.Util.Memory

  attr :rows, :list, default: []
  attr :meta, :map, default: nil
  attr :abridged, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"

  def notebooks_table(assigns) do
    ~H"""
    <.table
      id="notebook-display-table"
      variant={@meta && "paginated"}
      rows={@rows}
      meta={@meta}
      path={~p"/notebooks"}
      row_click={&JS.navigate(show_url(&1))}
    >
      <:col :let={notebook} :if={!@abridged} field={:id} label="ID"><%= notebook.id %></:col>
      <:col :let={notebook} field={:name} label="Name"><%= notebook.name %></:col>
      <:col :let={notebook} :if={!@abridged} field={:storage_size} label="Storage Size">
        <%= Memory.humanize(notebook.storage_size) %>
      </:col>
      <:col :let={notebook} :if={!@abridged} field={:memory_limits} label="Memory Limits">
        <%= Memory.humanize(notebook.memory_limits) %>
      </:col>
      <:action :let={notebook}>
        <.flex class="justify-items-center">
          <.button
            variant="minimal"
            link={edit_url(notebook)}
            icon={:pencil}
            id={"edit_notebook_" <> notebook.id}
          />

          <.tooltip target_id={"edit_notebook_" <> notebook.id}>
            Edit Notebook
          </.tooltip>

          <.button
            variant="minimal"
            link={notebook_path(notebook)}
            link_type="external"
            target="_blank"
            icon={:arrow_top_right_on_square}
            id={"open_notebook_" <> notebook.id}
          />

          <.tooltip target_id={"open_notebook_" <> notebook.id}>
            Open Notebook
          </.tooltip>

          <.button
            variant="minimal"
            link={show_url(notebook)}
            icon={:eye}
            id={"notebook_show_link_" <> notebook.id}
          />
          <.tooltip target_id={"notebook_show_link_" <> notebook.id}>
            Show Notebook
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  defp show_url(notebook), do: ~p"/notebooks/#{notebook}"
  defp edit_url(notebook), do: ~p"/notebooks/#{notebook}/edit"
  defp notebook_path(notebook), do: "//#{notebooks_host()}/#{notebook.name}"
end
