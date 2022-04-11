defmodule ControlServerWeb.LeftMenuLayout do
  use Phoenix.Component
  use PetalComponents

  alias CommonUI.Icons.Notebook
  alias ControlServerWeb.Layout

  @default_icon_class "group-hover:text-gray-500 flex-shrink-0 flex-shrink-0 -ml-1 mr-3 h-6 w-6 group"

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:title, fn -> [] end)
    |> assign_new(:inner_block, fn -> [] end)
    |> assign_new(:left_menu, fn -> [] end)
  end

  defp assign_menu_item_defaults(assigns) do
    assigns
    |> assign_new(:is_active, fn -> false end)
    |> assign_new(:icon, fn -> "database" end)
  end

  defp assign_menu_defaults(assigns) do
    assigns
    |> assign_new(:active, fn -> "" end)
    |> assign_new(:running_services, fn -> [] end)
  end

  defp left_menu_item(assigns) do
    assigns = assign_menu_item_defaults(assigns)

    ~H"""
    <.link link_type="live_patch" to={@to} class={menu_link_class(@is_active)}>
      <.left_icon type={@icon} />
      <span class="truncate">
        <%= @name %>
      </span>
    </.link>
    """
  end

  defp left_icon(assigns) do
    assigns = assign_new(assigns, :class, fn -> @default_icon_class end)

    ~H"""
    <%= case @type do %>
      <% "notebooks" -> %>
        <Notebook.render class={@class} />
      <% "home" -> %>
        <Heroicons.Solid.home class={@class} />
      <% "database" -> %>
        <Heroicons.Solid.database class={@class} />
      <% "lightning_bolt" -> %>
        <Heroicons.Solid.lightning_bolt class={@class} />
      <% "status_online" -> %>
        <Heroicons.Solid.status_online class={@class} />
      <% "external_link" -> %>
        <Heroicons.Solid.external_link class={@class} />
      <% "collection" -> %>
        <Heroicons.Solid.collection class={@class} />
      <% "table" -> %>
        <Heroicons.Solid.table class={@class} />
    <% end %>
    """
  end

  defp menu_link_class(true = _active),
    do:
      "text-pink-600 hover:bg-white group rounded-md px-3 py-2 flex items-center text-sm font-medium"

  defp menu_link_class(_active),
    do:
      "text-gray-600 hover:text-gray-900 hover:bg-astral-100 group rounded-md px-3 py-2 flex items-center text-sm font-medium"

  defdelegate title(assigns), to: Layout

  def data_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item to="/services/data" name="Home" icon="home" is_active={@active == "home"} />
    <.left_menu_item
      to="/services/data/postgres_clusters"
      name="Postgres Clusters"
      icon="database"
      is_active={@active == "postgres"}
    />
    <.left_menu_item
      to="/services/data/failover_clusters"
      name="Redis Clusters"
      icon="table"
      is_active={@active == "redis"}
    />
    <.left_menu_item
      to="/services/data/settings"
      name="Service Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />
    <.left_menu_item
      to="/services/data/status"
      name="Status"
      icon="status_online"
      is_active={@active == "status"}
    />
    """
  end

  def devtools_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to="/services/devtools/tools"
      name="Tools"
      icon="external_link"
      is_active={@active == "tools"}
    />
    <.left_menu_item
      to="/services/devtools/settings"
      name="Service Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />
    <.left_menu_item
      to="/services/devtools/knative_services"
      name="Knative Services"
      icon="collection"
      is_active={@active == "knative"}
    />
    <.left_menu_item
      to="/services/devtools/status"
      name="Status"
      icon="status_online"
      is_active={@active == "status"}
    />
    """
  end

  def ml_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item to="/services/ml" name="Home" icon="home" is_active={@active == "home"} />
    <.left_menu_item
      to="/services/ml/notebooks"
      name="Notebooks"
      icon="notebooks"
      is_active={@active == "notebooks"}
    />
    <.left_menu_item
      to="/services/ml/settings"
      name="Service Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />
    <.left_menu_item
      to="/services/ml/status"
      name="Status"
      icon="status_online"
      is_active={@active == "status"}
    />
    """
  end

  def monitoring_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to="/services/monitoring/tools"
      name="Tools"
      icon="external_link"
      is_active={@active == "tools"}
    />
    <.left_menu_item
      to="/services/monitoring/settings"
      name="Service Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />
    <.left_menu_item
      to="/services/monitoring/status"
      name="Status"
      icon="status_online"
      is_active={@active == "status"}
    />
    """
  end

  def security_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to="/services/security/settings"
      name="Service Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />
    <.left_menu_item
      to="/services/security/status"
      name="Status"
      icon="status_online"
      is_active={@active == "status"}
    />
    """
  end

  def network_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to="/services/network/settings"
      name="Service Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />
    <.left_menu_item
      to="/services/network/status"
      name="Status"
      icon="status_online"
      is_active={@active == "status"}
    />
    """
  end

  def body_section(assigns) do
    ~H"""
    <div class="shadow sm:rounded-md sm:overflow-hidden">
      <div class="bg-white py-6 px-4 space-y-6 sm:p-6">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def layout(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <Layout.layout>
      <:title>
        <%= render_slot(@title) %>
      </:title>
      <div class="lg:grid lg:grid-cols-12 lg:gap-x-5">
        <aside class="py-6 px-2 sm:px-6 lg:py-0 lg:px-0 lg:col-span-3">
          <nav class="space-y-1">
            <%= render_slot(@left_menu) %>
          </nav>
        </aside>
        <div class="space-y-6 sm:px-6 lg:px-0 lg:col-span-9">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </Layout.layout>
    """
  end
end
