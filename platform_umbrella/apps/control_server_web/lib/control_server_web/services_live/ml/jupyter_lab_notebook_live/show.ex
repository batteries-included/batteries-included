defmodule ControlServerWeb.ServicesLive.JupyterLabNotebook.Show do
  use ControlServerWeb, :surface_view

  alias ControlServer.Notebooks
  alias ControlServerWeb.IFrame
  alias ControlServerWeb.Layout

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

  defp page_title(_), do: "Jupyter lab notebook"

  @impl true
  def render(assigns) do
    ~F"""
    <Layout container_type={:iframe}>
      <IFrame src={"/x/notebooks/#{@jupyter_lab_notebook.name}/lab"} />
    </Layout>
    """
  end
end
