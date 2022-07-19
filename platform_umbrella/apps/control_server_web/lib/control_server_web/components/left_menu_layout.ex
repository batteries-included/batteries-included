defmodule ControlServerWeb.LeftMenuLayout do
  use ControlServerWeb, :component
  use PetalComponents

  import CommonUI.Icons.Devtools
  import CommonUI.Icons.Monitoring
  import CommonUI.Icons.Notebook
  import CommonUI.Icons.Network
  alias ControlServerWeb.Endpoint

  alias ControlServerWeb.Layout

  @default_icon_class "group-hover:text-gray-500 flex-shrink-0 -ml-1 mr-3 h-6 w-6 group"

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:title, fn -> nil end)
    |> assign_new(:inner_block, fn -> nil end)
    |> assign_new(:left_menu, fn -> nil end)
    |> assign_new(:current_user, fn -> nil end)
  end

  defp assign_menu_item_defaults(assigns) do
    assigns
    |> assign_new(:is_active, fn -> false end)
    |> assign_new(:icon, fn -> "database" end)
    |> assign_new(:link_type, fn -> "live_patch" end)
  end

  defp assign_menu_defaults(assigns) do
    assigns
    |> assign_new(:active, fn -> "" end)
    |> assign_new(:base_services, fn -> [] end)
  end

  defp left_menu_item(assigns) do
    assigns = assign_menu_item_defaults(assigns)

    ~H"""
    <.link link_type={@link_type} to={@to} class={menu_link_class(@is_active)}>
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
        <.notebook_icon class={@class} />
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
      <% "grafana" -> %>
        <.grafana_icon class={@class} />
      <% "prometheus" -> %>
        <.prometheus_icon class={@class} />
      <% "alert_manager" -> %>
        <.alert_manager_icon class={@class} />
      <% "gitea" -> %>
        <.gitea_icon class={@class} />
      <% "kiali" -> %>
        <.kiali_icon class={@class} />
      <% "tekton" -> %>
        <.tekton_icon class={@class} />
      <% "harbor" -> %>
        <.harbor_icon class={@class} />
      <% "user_group" -> %>
        <Heroicons.Solid.user_group class={@class} />
    <% end %>
    """
  end

  defp menu_link_class(true = _active),
    do:
      "text-pink-600 hover:bg-white group rounded-md px-3 py-2 flex items-center text-sm font-medium"

  defp menu_link_class(_active),
    do:
      "text-gray-500 hover:text-gray-900 hover:bg-astral-100 group rounded-md px-3 py-2 flex items-center text-sm font-medium"

  defdelegate title(assigns), to: Layout

  def data_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to={Routes.data_home_path(Endpoint, :index)}
      name="Home"
      icon="home"
      is_active={@active == "home"}
    />
    <.left_menu_item
      to={Routes.postgres_clusters_path(Endpoint, :index)}
      name="Postgres Clusters"
      icon="database"
      is_active={@active == "postgres"}
    />
    <.left_menu_item
      to={Routes.redis_path(Endpoint, :index)}
      name="Redis Clusters"
      icon="table"
      is_active={@active == "redis"}
    />
    <.left_menu_item
      to={Routes.service_settings_path(Endpoint, :data)}
      name="Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />
    """
  end

  def devtools_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to={Routes.knative_services_index_path(Endpoint, :index)}
      name="Knative Services"
      icon="collection"
      is_active={@active == "knative"}
    />
    <.left_menu_item
      to={Routes.service_settings_path(Endpoint, :devtools)}
      name="Service Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />

    <%= for base_service <- @base_services do %>
      <.base_service_menu_item service_type={base_service.service_type} />
    <% end %>
    """
  end

  def ml_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to={Routes.jupyter_lab_notebook_index_path(Endpoint, :index)}
      name="Notebooks"
      icon="notebooks"
      is_active={@active == "notebooks"}
    />
    <.left_menu_item
      to={Routes.service_settings_path(Endpoint, :ml)}
      name="Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />
    """
  end

  def monitoring_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to={Routes.service_settings_path(Endpoint, :monitoring)}
      name="Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />

    <%= for base_service <- @base_services do %>
      <.base_service_menu_item service_type={base_service.service_type} />
    <% end %>
    """
  end

  defp base_service_menu_item(assigns) do
    ~H"""
    <%= case @service_type do %>
      <% :grafana -> %>
        <.left_menu_item
          to={KubeResources.Grafana.view_url()}
          name="Grafana"
          icon="grafana"
          link_type="a"
        />
      <% :prometheus -> %>
        <.left_menu_item
          to={KubeResources.Prometheus.view_url()}
          name="Prometheus"
          icon="prometheus"
          link_type="a"
        />
      <% :alert_manager -> %>
        <.left_menu_item
          to={KubeResources.AlertManager.view_url()}
          name="Alert Manager"
          icon="alert_manager"
          link_type="a"
        />
      <% :gitea -> %>
        <.left_menu_item to={KubeResources.Gitea.view_url()} name="Gitea" icon="gitea" link_type="a" />
      <% :kiali -> %>
        <.left_menu_item
          to={KubeResources.KialiServer.view_url()}
          name="Kiali"
          icon="kiali"
          link_type="a"
        />
      <% :tekton_dashboard -> %>
        <.left_menu_item
          to={KubeResources.TektonDashboard.view_url()}
          name="Tekton Dashboard"
          icon="tekton"
          link_type="a"
        />
      <% :harbor -> %>
        <.left_menu_item
          to={KubeResources.Harbor.view_url()}
          name="Harbor"
          icon="harbor"
          link_type="a"
        />
      <% _ -> %>
    <% end %>
    """
  end

  def security_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to={Routes.user_index_path(Endpoint, :index)}
      name="Users"
      icon="user_group"
      is_active={@active == "users"}
    />
    <.left_menu_item
      to={Routes.service_settings_path(Endpoint, :security)}
      name="Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />
    """
  end

  def network_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to={Routes.service_settings_path(Endpoint, :network)}
      name="Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
    />

    <%= for base_service <- @base_services do %>
      <.base_service_menu_item service_type={base_service.service_type} />
    <% end %>
    """
  end

  def magic_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to={Routes.resource_list_path(Endpoint, :pods)}
      name="Pods"
      icon="lightning_bolt"
      is_active={@active == "pods"}
    />
    <.left_menu_item
      to={Routes.resource_list_path(Endpoint, :deployments)}
      name="Deployments"
      icon="lightning_bolt"
      is_active={@active == "deployments"}
    />
    <.left_menu_item
      to={Routes.resource_list_path(Endpoint, :stateful_sets)}
      name="Stateful Sets"
      icon="lightning_bolt"
      is_active={@active == "stateful_sets"}
    />
    <.left_menu_item
      to={Routes.resource_list_path(Endpoint, :nodes)}
      name="Nodes"
      icon="lightning_bolt"
      is_active={@active == "nodes"}
    />
    <.left_menu_item
      to={Routes.resource_list_path(Endpoint, :services)}
      name="Services"
      icon="lightning_bolt"
      is_active={@active == "services"}
    />
    <.left_menu_item
      to={Routes.kube_snapshot_list_path(Endpoint, :index)}
      name="Kube Deploys"
      icon="lightning_bolt"
      is_active={@active == "snapshots"}
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

  def section_title(assigns) do
    ~H"""
    <.h3 class="text-right">
      <%= render_slot(@inner_block) %>
    </.h3>
    """
  end

  def layout(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <Layout.layout title={@title}>
      <div class="lg:grid lg:grid-cols-9 lg:gap-x-5">
        <aside class="py-6 px-2 sm:px-6 lg:py-0 lg:px-0 lg:col-span-2">
          <nav class="space-y-1">
            <%= render_slot(@left_menu) %>
          </nav>
        </aside>
        <div class="space-y-6 sm:px-6 lg:px-0 lg:col-span-7">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </Layout.layout>
    """
  end
end
