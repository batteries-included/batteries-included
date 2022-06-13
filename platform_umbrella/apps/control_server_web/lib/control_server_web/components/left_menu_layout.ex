defmodule ControlServerWeb.LeftMenuLayout do
  use Phoenix.Component
  use PetalComponents

  import CommonUI.Icons.Devtools
  import CommonUI.Icons.Monitoring
  import CommonUI.Icons.Notebook
  import CommonUI.Icons.Network

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
    """
  end

  def devtools_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
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

    <%= for base_service <- @base_services do %>
      <.base_service_menu_item service_type={base_service.service_type} />
    <% end %>
    """
  end

  def ml_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
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
    """
  end

  def monitoring_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to="/services/monitoring/settings"
      name="Service Settings"
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
      to="/services/security/settings"
      name="Service Settings"
      icon="lightning_bolt"
      is_active={@active == "settings"}
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

    <%= for base_service <- @base_services do %>
      <.base_service_menu_item service_type={base_service.service_type} />
    <% end %>
    """
  end

  def magic_menu(assigns) do
    assigns = assign_menu_defaults(assigns)

    ~H"""
    <.left_menu_item
      to="/internal/pods"
      name="Pods"
      icon="lightning_bolt"
      is_active={@active == "pods"}
    />
    <.left_menu_item
      to="/internal/deployments"
      name="Deployments"
      icon="lightning_bolt"
      is_active={@active == "deployments"}
    />
    <.left_menu_item
      to="/internal/stateful_sets"
      name="Stateful Sets"
      icon="lightning_bolt"
      is_active={@active == "stateful_sets"}
    />
    <.left_menu_item
      to="/internal/nodes"
      name="Nodes"
      icon="lightning_bolt"
      is_active={@active == "nodes"}
    />
    <.left_menu_item
      to="/internal/services"
      name="Services"
      icon="lightning_bolt"
      is_active={@active == "services"}
    />
    <.left_menu_item
      to="/internal/kube_snapshots"
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
    <Layout.layout>
      <:title>
        <%= render_slot(@title) %>
      </:title>
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
