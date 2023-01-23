defmodule ControlServerWeb.NotebooksTable do
  use ControlServerWeb, :html

  import KubeServices.SystemState.SummaryHosts

  attr :notebooks, :list, default: []

  def notebooks_table(assigns) do
    ~H"""
    <.table id="notebook-display-table" rows={@notebooks}>
      <:col :let={notebook} label="Name"><%= notebook.name %></:col>
      <:col :let={notebook} label="Image"><%= notebook.image %></:col>
      <:action :let={notebook}>
        <.link variant="external" href={notebook_path(notebook)}>
          Open Notebook
        </.link>
      </:action>
    </.table>
    """
  end

  defp notebook_path(notebook), do: "//#{notebooks_host()}/#{notebook.name}"
end
