defmodule ControlServerWeb.Live.JupyterLabNotebook.Show do
  use ControlServerWeb, :live_view

  import ControlServerWeb.IFrame
  import ControlServerWeb.Layout

  alias ControlServer.Notebooks

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
    ~H"""
    <.layout container_type={:iframe}>
      <.iframe src={"/x/notebooks/#{@jupyter_lab_notebook.name}/lab"} />
    </.layout>
    """
  end
end
