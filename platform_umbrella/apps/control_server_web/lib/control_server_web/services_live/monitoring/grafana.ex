defmodule ControlServerWeb.ServicesLive.Grafana do
  use ControlServerWeb, :surface_view

  alias ControlServerWeb.IFrame
  alias ControlServerWeb.Layout

  @impl true
  def render(assigns) do
    ~F"""
    <Layout container_type={:iframe}>
      <IFrame src="/x/grafana" />
    </Layout>
    """
  end
end
