defmodule ControlServerWeb.Live.JupyterLabNotebook.Display do
  use ControlServerWeb, :component

  alias ControlServerWeb.Router.Helpers, as: Routes

  attr :notebooks, :list, default: []

  def notebook_display(assigns) do
    ~H"""
    <.table id="notebook-display-table" rows={@notebooks}>
      <:col :let={notebook} label="Name"><%= notebook.name %></:col>
      <:col :let={notebook} label="Image"><%= notebook.image %></:col>
      <:action :let={notebook}>
        <.link navigate={notebook_path(notebook)}>
          Open Notebook <Heroicons.arrow_top_right_on_square class="w-5 h-5" />
        </.link>
      </:action>
    </.table>
    """
  end

  def notebook_show_path(notebook) do
    Routes.jupyter_lab_notebook_show_path(
      ControlServerWeb.Endpoint,
      :index,
      notebook.id
    )
  end

  defp notebook_path(notebook), do: KubeResources.Notebooks.view_url(notebook)
end
