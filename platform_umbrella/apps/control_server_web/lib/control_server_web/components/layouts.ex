defmodule ControlServerWeb.Layouts do
  @moduledoc false
  use ControlServerWeb, :html

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
      main_menu_items={[
        %{
          name: :home,
          label: "Home",
          path: ~p"/",
          icon: :home
        },
        %{
          name: :data,
          label: "Datastores",
          path: ~p"/data",
          icon: :circle_stack
        },
        %{
          name: :devtools,
          label: "Devtools",
          path: ~p"/devtools",
          icon: :wrench
        },
        %{
          name: :monitoring,
          label: "Monitoring",
          path: ~p"/monitoring",
          icon: :chart_bar_square
        },
        %{
          name: :net_sec,
          label: "Net/Security",
          path: ~p"/net_sec",
          icon: :shield_check
        },
        %{
          name: :ml,
          label: "ML",
          path: ~p"/ml",
          icon: :beaker
        },
        %{
          name: :kubernetes,
          label: "Kubernetes",
          path: ~p"/kube/pods",
          icon: :globe_alt
        },
        %{
          name: :magic,
          label: "Magic",
          path: ~p"/magic",
          icon: :sparkles
        }
      ]}
      bottom_menu_items={[]}
      current_page={if assigns[:current_page], do: @current_page, else: nil}
    >
      <%= @inner_content %>
    </ControlServerWeb.SidebarLayout.sidebar_layout>
    """
  end
end
