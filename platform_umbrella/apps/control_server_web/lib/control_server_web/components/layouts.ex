defmodule ControlServerWeb.Layouts do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Batteries.Catalog

  embed_templates("layouts/*")

  @doc """
  In your live view:

      use ControlServerWeb, {:live_view, layout: :sidebar}
  """
  def sidebar(assigns) do
    ~H"""
    <.flash_group flash={@flash} global />

    <.alert
      type="fixed"
      variant="disconnected"
      phx-connected={hide_alert()}
      phx-disconnected={show_alert()}
      autoshow={false}
    />

    <ControlServerWeb.SidebarLayout.sidebar_layout
      main_menu_items={Catalog.groups_for_nav()}
      current_page={if assigns[:current_page], do: @current_page, else: nil}
    >
      {@inner_content}
    </ControlServerWeb.SidebarLayout.sidebar_layout>
    """
  end
end
