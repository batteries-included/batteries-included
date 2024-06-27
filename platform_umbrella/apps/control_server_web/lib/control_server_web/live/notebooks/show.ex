defmodule ControlServerWeb.Live.JupyterLabNotebookShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.Util.Memory
  alias ControlServer.Notebooks

  def mount(%{"id" => id}, _session, socket) do
    notebook = Notebooks.get_jupyter_lab_notebook!(id, preload: [:project])

    {:ok,
     socket
     |> assign(:page_title, "Jupyter Notebook")
     |> assign(:notebook, notebook)}
  end

  def handle_event("delete", _params, socket) do
    case Notebooks.delete_jupyter_lab_notebook(socket.assigns.notebook) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Notebook successfully deleted")
         |> push_navigate(to: ~p"/notebooks")}

      _ ->
        {:noreply, put_flash(socket, :global_error, "Could not delete notebook")}
    end
  end

  def render(assigns) do
    ~H"""
    <.page_header title={"Jupyter Notebook: #{@notebook.name}"} back_link={~p"/notebooks"}>
      <:menu>
        <.badge :if={@notebook.project_id}>
          <:item label="Project"><%= @notebook.project.name %></:item>
        </.badge>
      </:menu>

      <.flex>
        <.tooltip target_id="edit-tooltip">Edit Notebook</.tooltip>
        <.tooltip target_id="delete-tooltip">Delete Notebook</.tooltip>
        <.flex gaps="0">
          <.button id="edit-tooltip" variant="icon" icon={:pencil} link={edit_url(@notebook)} />
          <.button
            id="delete-tooltip"
            variant="icon"
            icon={:trash}
            phx-click="delete"
            data-confirm={"Are you sure you want to delete the #{@notebook.name} notebook?"}
          />
        </.flex>
      </.flex>
    </.page_header>

    <.grid columns={%{sm: 1, lg: 2}}>
      <.panel title="Details" variant="gray">
        <.data_list>
          <:item title="Image">
            <%= @notebook.image %>
          </:item>
          <:item title="Storage Size">
            <%= Memory.humanize(@notebook.storage_size) %>
          </:item>
          <:item :if={@notebook.memory_limits} title="Memory limits">
            <%= Memory.humanize(@notebook.memory_limits) %>
          </:item>
          <:item title="Started">
            <.relative_display time={@notebook.inserted_at} />
          </:item>
        </.data_list>
      </.panel>

      <.flex column class="justify-start">
        <.a variant="bordered" href={notebook_path(@notebook)}>Open Notebook</.a>
      </.flex>
    </.grid>
    """
  end

  defp edit_url(notebook), do: ~p"/notebooks/#{notebook}/edit"

  defp notebook_path(notebook), do: "//#{notebooks_host()}/#{notebook.name}"
end
