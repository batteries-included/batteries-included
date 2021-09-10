defmodule ControlServerWeb.ServicesLive.Prometheus do
  use ControlServerWeb, :surface_view

  alias ControlServerWeb.IFrame
  alias ControlServerWeb.Layout

  @impl true
  def render(assigns) do
    ~F"""
    <Layout container_type={:iframe}>
      <IFrame src="/x/prometheus" />
    </Layout>
    """
  end
end
