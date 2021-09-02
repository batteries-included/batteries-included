defmodule ControlServerWeb.ServicesLive.JupyterLabNotebook.Show do
  use ControlServerWeb, :surface_view

  alias ControlServer.Notebooks
  alias ControlServerWeb.Layout

  alias Surface.Components.LiveRedirect

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:jupyter_lab_notebook, Notebooks.get_jupyter_lab_notebook!(id))}
  end

  defp page_title(_), do: "Show Jupyter lab notebook"

  @impl true
  def render(assigns) do
    ~F"""
    <Layout>
      <h1>Show Jupyter lab notebook</h1>

      <ul>
        <li>
          <strong>Name:</strong>
          {@jupyter_lab_notebook.name}
        </li>

        <li>
          <strong>Image:</strong>
          {@jupyter_lab_notebook.image}
        </li>
      </ul>

      <span>
        <LiveRedirect
          label="Back"
          to={Routes.services_jupyter_lab_notebook_index_path(@socket, :index)}
        />
      </span>
    </Layout>
    """
  end
end
