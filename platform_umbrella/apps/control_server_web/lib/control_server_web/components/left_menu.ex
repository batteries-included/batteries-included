defmodule ControlServerWeb.LeftMenu do
  use ControlServerWeb, :live_component

  import CommonUI.Icons.Database
  import CommonUI.Icons.Devtools
  import CommonUI.Icons.Monitoring
  import CommonUI.Icons.Notebook
  import CommonUI.Icons.Network
  import CommonUI.Icons.Rook

  alias ControlServer.Batteries

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign_active(assigns.active)
     |> assign_group(assigns.group)
     |> assign_batteries(assigns.group)}
  end

  defp assign_batteries(socket, group) when is_binary(group) do
    assign_batteries(socket, String.to_existing_atom(group))
  end

  defp assign_batteries(socket, group) do
    assign(socket, :batteries, Batteries.list_system_batteries_for_group(group))
  end

  defp assign_active(socket, active) when is_binary(active) do
    assign_active(socket, String.to_existing_atom(active))
  end

  defp assign_active(socket, active) do
    assign(socket, :active, active)
  end

  defp assign_group(socket, group) when is_binary(group) do
    assign_group(socket, String.to_existing_atom(group))
  end

  defp assign_group(socket, group) do
    assign(socket, :group, group)
  end

  attr :name, :string, required: true
  attr :navigate, :any
  attr :href, :any
  attr :is_active, :boolean, default: false

  attr :active_class, :string,
    default:
      "text-pink-600 hover:bg-white group rounded-md px-3 py-2 flex items-center text-sm font-medium"

  attr :inactive_class, :string,
    default:
      "text-gray-500 hover:text-gray-900 hover:bg-astral-100 group rounded-md px-3 py-2 flex items-center text-sm font-medium"

  slot :inner_block

  defp menu_item(%{navigate: _} = assigns) do
    ~H"""
    <.link navigate={@navigate} class={[@is_active && @active_class, !@is_active && @inactive_class]}>
      <%= render_slot(@inner_block) %>
      <span class="truncate">
        <%= @name %>
      </span>
    </.link>
    """
  end

  defp menu_item(%{href: _} = assigns) do
    ~H"""
    <.link href={@href} class={[@is_active && @active_class, !@is_active && @inactive_class]}>
      <%= render_slot(@inner_block) %>
      <span class="truncate">
        <%= @name %>
      </span>
    </.link>
    """
  end

  attr :battery, :any, default: %{type: :unknown}
  attr :active, :string, default: nil

  attr :icon_class, :any,
    default: "group-hover:text-gray-500 flex-shrink-0 -ml-1 mr-3 h-6 w-6 group"

  defp battery_menu_item(%{battery: %{type: :postgres_operator}} = assigns) do
    ~H"""
    <.menu_item
      navigate={~p"/postgres/clusters"}
      name="Postgres"
      is_active={@active == :postgres_operator}
    >
      <Heroicons.circle_stack solid class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :redis}} = assigns) do
    ~H"""
    <.menu_item navigate={~p"/redis/clusters"} name="Redis" is_active={@active == :redis}>
      <.redis_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :rook}} = assigns) do
    ~H"""
    <.menu_item navigate={~p"/ceph"} name="Ceph" is_active={@active == :rook}>
      <.ceph_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :knative_serving}} = assigns) do
    ~H"""
    <.menu_item
      navigate={~p"/knative/services"}
      name="Knative Serving"
      is_active={@active == :knative_serving}
    >
      <Heroicons.square_3_stack_3d solid class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :notebooks}} = assigns) do
    ~H"""
    <.menu_item navigate={~p"/notebooks"} name="Notebooks" is_active={@active == :notebooks}>
      <.notebook_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :grafana}} = assigns) do
    ~H"""
    <.menu_item href={KubeResources.Grafana.view_url()} name="Grafana" is_active={@active == :grafana}>
      <.grafana_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :prometheus}} = assigns) do
    ~H"""
    <.menu_item
      href={KubeResources.Prometheus.view_url()}
      name="Prometheus"
      is_active={@active == :prometheus}
    >
      <.prometheus_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :alert_manager}} = assigns) do
    ~H"""
    <.menu_item
      href={KubeResources.Alertmanager.view_url()}
      name="Alert Manager"
      is_active={@active == :alert_manager}
    >
      <.alert_manager_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :gitea}} = assigns) do
    ~H"""
    <.menu_item href={KubeResources.Gitea.view_url()} name="Gitea" is_active={@active == :gitea}>
      <.gitea_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :harbor}} = assigns) do
    ~H"""
    <.menu_item href={KubeResources.Harbor.view_url()} name="Harbor" is_active={@active == :harbor}>
      <.harbor_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :kiali}} = assigns) do
    ~H"""
    <.menu_item href={KubeResources.Kiali.view_url()} name="Kiali" is_active={@active == :kiali}>
      <.kiali_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: _}} = assigns), do: ~H||

  attr :active, :string, default: nil
  attr :group, :any

  attr :icon_class, :any,
    default: "group-hover:text-gray-500 flex-shrink-0 -ml-1 mr-3 h-6 w-6 group"

  defp group_menu_item(%{group: :magic} = assigns) do
    ~H"""
    <.menu_item navigate={~p"/timeline"} name="Timeline" is_active={@active == :timeline}>
      <Heroicons.clock class={@icon_class} />
    </.menu_item>
    <.menu_item navigate={~p"/kube/pods"} name="Kubernetes" is_active={@active == :kube_resources}>
      <Heroicons.rectangle_group class={@icon_class} />
    </.menu_item>
    <.menu_item
      navigate={~p"/kube/snapshots"}
      name="Snapshot Deploys"
      is_active={@active == :kube_snapshots}
    >
      <Heroicons.rocket_launch class={@icon_class} />
    </.menu_item>

    <.menu_item
      navigate={~p"/batteries"}
      name="Installed Batteries"
      is_active={@active == :installed_batteries}
    >
      <Heroicons.battery_100 class={@icon_class} />
    </.menu_item>
    <.menu_item navigate={~p"/batteries/magic"} name="Batteries" is_active={@active == :batteries}>
      <Heroicons.battery_0 class={@icon_class} />
    </.menu_item>
    """
  end

  defp group_menu_item(%{group: _} = assigns) do
    ~H"""
    <.menu_item navigate={~p"/batteries/#{@group}"} name="Batteries" is_active={@active == :batteries}>
      <Heroicons.battery_0 class={@icon_class} />
    </.menu_item>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <nav class="space-y-1">
      <.battery_menu_item :for={battery <- @batteries} battery={battery} active={@active} />
      <.group_menu_item group={@group} active={@active} />
    </nav>
    """
  end
end
