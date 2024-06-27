defmodule ControlServerWeb.NotebooksTable do
  @moduledoc false
  use ControlServerWeb, :html

  import KubeServices.SystemState.SummaryHosts

  attr :rows, :list, default: []
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def notebooks_table(assigns) do
    ~H"""
    <.table id="notebook-display-table" rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={notebook} :if={!@abbridged} label="ID"><%= notebook.id %></:col>
      <:col :let={notebook} label="Name"><%= notebook.name %></:col>
      <:col :let={notebook} label="Image"><%= notebook.image %></:col>
      <:action :let={notebook}>
        <.flex class="justify-items-center">
          <.button
            variant="minimal"
            link={show_url(notebook)}
            icon={:eye}
            id={"show_notebook_" <> notebook.id}
          />

          <.tooltip target_id={"show_notebook_" <> notebook.id}>
            Show Notebook
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
        </.flex>
      </:action>
    </.table>
    """
  end

  defp show_url(notebook), do: ~p"/notebooks/#{notebook}"

  defp notebook_path(notebook), do: "//#{notebooks_host()}/#{notebook.name}"
end
