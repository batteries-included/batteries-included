defmodule ControlServerWeb.Layouts do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonUI.Icons.Batteries
  import ControlServerWeb.LeftMenu

  embed_templates("layouts/*")

  def fresh(assigns) do
    ~H"""
    <div
      class="fresh-container flex bg-gray-50 h-full w-full min-h-screen"
      x-data="{'menuOpen': true}"
    >
      <header class="navbar h-20 fixed bg-white shadow-lg p-6">
        <div class="flex-none">
          <button
            class="inline-flex hover:text-pink-500 transition-none"
            x-on:click="menuOpen = ! menuOpen"
          >
            <Heroicons.bars_3_bottom_right class="inline-block h-8 w-auto stroke-current" />
          </button>
        </div>
        <div class="flex-1">
          <.a
            class="inline-flex normal-case text-xl transition-none animation-none m-4 justify-center"
            navigate={~p|/|}
          >
            <.batteries_logo class="h-10 w-auto mr-6" />
            <span class="align-middle my-auto">Batteries Included</span>
          </.a>
        </div>
      </header>

      <.left_menu
        x-show="menuOpen"
        x-cloak
        x-transition
        installed_batteries={Map.get(assigns, :installed_batteries, [])}
        page_group={Map.get(assigns, :page_group, nil)}
        page_detail_type={Map.get(assigns, :page_detail_type, nil)}
      />

      <main class="flex-auto relative p-6 space-y-4 sm:space-y-8">
        <%= @inner_content %>
      </main>
    </div>
    """
  end

  @doc """
  In your live view:

      use ControlServerWeb, {:live_view, layout: :sidebar}
  """
  def sidebar(assigns) do
    ~H"""
    <ControlServerWeb.SidebarLayout.sidebar_layout
      main_menu_items={[
        %{
          name: :home,
          label: "Home",
          path: ~p"/",
          icon: :home
        },
        %{
          name: :datastores,
          label: "Datastores",
          path: ~p"/postgres",
          icon: :circle_stack
        },
        %{
          name: :devtools,
          label: "Devtools",
          path: ~p"/",
          icon: :wrench
        },
        %{
          name: :monitoring,
          label: "Monitoring",
          path: ~p"/",
          icon: :chart_bar_square
        },
        %{
          name: :netsecurity,
          label: "Net/Security",
          path: ~p"/",
          icon: :shield_check
        },
        %{
          name: :ml,
          label: "ML",
          path: ~p"/",
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
          path: ~p"/snapshot_apply",
          icon: :sparkles
        }
      ]}
      bottom_menu_items={[
        %{
          name: :settings,
          label: "Settings",
          path: ~p"/",
          icon: :adjustments_horizontal
        }
      ]}
      current_page={if assigns[:current_page], do: @current_page, else: nil}
    >
      <%= @inner_content %>
    </ControlServerWeb.SidebarLayout.sidebar_layout>
    """
  end
end
