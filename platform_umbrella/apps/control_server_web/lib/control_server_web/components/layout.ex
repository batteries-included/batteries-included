defmodule ControlServerWeb.Layout do
  use ControlServerWeb, :component
  use PetalComponents

  import CommonUI.Icons.Devtools

  alias CommonUI.Layout, as: BaseLayout
  alias ControlServerWeb.Endpoint

  @default_menu_item_class "hover:bg-astral-100 hover:text-pink-500 text-gray-500"
  @default_icon_class "h-6 w-6 text-astral-500 group-hover:text-pink-500"

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:menu_item_class, fn -> @default_menu_item_class end)
    |> assign_new(:icon_class, fn -> @default_icon_class end)
    |> assign_new(:container_type, fn -> :default end)
    |> assign_new(:title, fn -> nil end)
    |> assign_new(:user_id, fn -> nil end)
  end

  defdelegate title(assigns), to: BaseLayout

  defp assign_icon_defaults(assigns) do
    assigns
    |> assign_new(:class, fn -> @default_icon_class end)
    |> assign_new(:type, fn -> "database" end)
  end

  defp icon(assigns) do
    assigns = assign_icon_defaults(assigns)

    ~H"""
    <%= case @type do %>
      <% "database" -> %>
        <Heroicons.Outline.database class={@class} />
      <% "beaker" -> %>
        <Heroicons.Outline.beaker class={@class} />
      <% "chart_bar" -> %>
        <Heroicons.Outline.chart_bar class={@class} />
      <% "globe_alt" -> %>
        <Heroicons.Outline.globe_alt class={@class} />
      <% "lock_closed" -> %>
        <Heroicons.Outline.lock_closed class={@class} />
      <% "sparkles" -> %>
        <Heroicons.Outline.sparkles class={@class} />
      <% "devtools" -> %>
        <.devtools_icon class={@class} />
    <% end %>
    """
  end

  def menu_item(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <BaseLayout.menu_item to={@to} name={@name} class={@menu_item_class}>
      <.icon class={@icon_class} type={@icon} />
    </BaseLayout.menu_item>
    """
  end

  def layout(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <BaseLayout.layout bg_class="bg-white" container_type={@container_type} title={@title}>
      <:user_menu>
        <%= if @user_id do %>
          <div class="dropdown dropdown-end mt-2">
            <label tabindex="0" class="btn btn-ghost btn-circle avatar">
              <div class="w-10 rounded-full">
                <img src={"https://robohash.org/#{@user_id}?size=80x80"} />
              </div>
            </label>
            <ul
              tabindex="0"
              class="mt-4 p-2 shadow menu menu-compact dropdown-content bg-base-100 rounded-box w-52"
            >
              <li>
                <.link to={Routes.user_settings_path(Endpoint, :edit)}>Settings</.link>
              </li>
              <li>
                <.link to={Routes.user_session_path(Endpoint, :delete)} method={:delete}>
                  Logout
                </.link>
              </li>
            </ul>
          </div>
        <% end %>
      </:user_menu>
      <:main_menu>
        <.menu_item to={Routes.data_home_path(Endpoint, :index)} name="Data" icon="database" />
        <.menu_item
          to={Routes.jupyter_lab_notebook_index_path(Endpoint, :index)}
          name="ML"
          icon="beaker"
        />
        <.menu_item
          to={Routes.service_settings_path(Endpoint, :monitoring)}
          name="Monitoring"
          icon="chart_bar"
        />
        <.menu_item
          to={Routes.service_settings_path(Endpoint, :devtools)}
          name="Devtools"
          icon="devtools"
        />
        <.menu_item
          to={Routes.service_settings_path(Endpoint, :security)}
          name="Security"
          icon="lock_closed"
        />
        <.menu_item
          to={Routes.service_settings_path(Endpoint, :network)}
          name="Network"
          icon="globe_alt"
        />
        <.menu_item to={Routes.resource_list_path(Endpoint, :pod)} name="Magic" icon="sparkles" />
      </:main_menu>
      <%= render_slot(@inner_block) %>
    </BaseLayout.layout>
    """
  end
end
