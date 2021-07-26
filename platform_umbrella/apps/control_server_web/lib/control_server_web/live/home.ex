defmodule ControlServerWeb.Live.Home do
  use ControlServerWeb, :surface_view

  alias ControlServerWeb.Layout

  def render(assigns) do
    ~F"""
    <Layout>
      Coming Soon
    </Layout>
    """
  end
end
