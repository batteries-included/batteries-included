defmodule ControlServerWeb.ServicesLive.Prometheus do
  use ControlServerWeb, :surface_view

  alias ControlServerWeb.Layout

  @impl true
  def render(assigns) do
    ~F"""
    <Layout>
      <iframe src="http://localhost:8081/x/prometheus" class="w-full iframe-container" />
    </Layout>
    """
  end
end
