defmodule ControlServerWeb.Live.JupyterLabNotebookShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.ActionsDropdown
  import ControlServerWeb.Containers.EnvValuePanel
  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.Util.Memory
  alias ControlServer.Notebooks

  def mount(%{"id" => id}, _session, socket) do
    notebook = Notebooks.get_jupyter_lab_notebook!(id, preload: [:project])

    {:ok,
     socket
     |> assign(:current_page, :ai)
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
          <:item label="Project" navigate={~p"/projects/#{@notebook.project_id}/show"}>
            {@notebook.project.name}
          </:item>
        </.badge>
      </:menu>

      <.flex>
        <.actions_dropdown>
          <.dropdown_link navigate={edit_url(@notebook)} icon={:pencil}>
            Edit Notebook
          </.dropdown_link>

          <.dropdown_button
            class="w-full"
            icon={:trash}
            phx-click="delete"
            data-confirm={"Are you sure you want to delete the #{@notebook.name} name?"}
          >
            Delete Notebook
          </.dropdown_button>
        </.actions_dropdown>
      </.flex>
    </.page_header>

    <.grid columns={%{sm: 1, lg: 2}}>
      <.panel title="Details" variant="gray">
        <.data_list>
          <:item title="Image">
            {@notebook.image}
          </:item>
          <:item title="Storage Size">
            {Memory.humanize(@notebook.storage_size)}
          </:item>
          <:item :if={@notebook.memory_limits} title="Memory limits">
            {Memory.humanize(@notebook.memory_limits)}
          </:item>
          <:item title="Started">
            <.relative_display time={@notebook.inserted_at} />
          </:item>
        </.data_list>
      </.panel>

      <.flex column class="justify-start">
        <.a variant="bordered" href={notebook_path(@notebook)}>Open Notebook</.a>
      </.flex>

      <.env_var_panel env_values={@notebook.env_values} class="lg:col-span-2" />
    </.grid>
    """
  end

  defp edit_url(notebook), do: ~p"/notebooks/#{notebook}/edit"
  defp notebook_path(notebook), do: "//#{notebooks_host()}/#{notebook.name}"
end
