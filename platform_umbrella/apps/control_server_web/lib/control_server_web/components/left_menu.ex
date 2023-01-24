defmodule ControlServerWeb.LeftMenu do
  use ControlServerWeb, :live_component

  import CommonUI.Icons.Database
  import CommonUI.Icons.Devtools
  import CommonUI.Icons.Monitoring
  import CommonUI.Icons.Network
  import CommonUI.Icons.Notebook
  import CommonUI.Icons.Rook

  import KubeServices.SystemState.SummaryHosts

  alias ControlServer.Batteries

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign_active(assigns.active)
     |> assign_group(assigns.group)
     |> assign_batteries(assigns.group)}
  end

  defp assign_batteries(socket, :projects) do
    assign(socket, :batteries, [])
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

  attr(:name, :string, required: true)
  attr(:navigate, :any)
  attr(:href, :any)
  attr(:is_active, :boolean, default: false)

  attr(:active_class, :string,
    default:
      "text-pink-500 hover:text-pink-600 hover:bg-pink-50/50 hover:shadow-sm group rounded-md px-3 py-2 flex items-center text-sm font-medium"
  )

  attr(:inactive_class, :string,
    default:
      "text-gray-600 hover:text-gray-900 hover:bg-pink-50/50 hover:shadow-sm group rounded-md px-3 py-2 flex items-center text-sm font-medium"
  )

  slot(:inner_block)

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
    <.link href={@href} class={menu_item_class(@is_active, @active_class, @inactive_class)}>
      <%= render_slot(@inner_block) %>
      <span class="truncate">
        <%= @name %>
      </span>
    </.link>
    """
  end

  defp menu_item_class(true = _is_active, active_class, _), do: active_class
  defp menu_item_class(false = _is_active, _, inactive_class), do: inactive_class

  attr(:battery, :any, default: %{type: :unknown})
  attr(:active, :string, default: nil)

  attr(:icon_class, :any, default: "flex-shrink-0 -ml-1 mr-3 h-6 w-6 group")

  defp battery_menu_item(%{battery: %{type: :postgres_operator}} = assigns) do
    ~H"""
    <.menu_item navigate={~p"/postgres"} name="Postgres" is_active={@active == :postgres_operator}>
      <Heroicons.circle_stack solid class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :redis}} = assigns) do
    ~H"""
    <.menu_item navigate={~p"/redis"} name="Redis" is_active={@active == :redis}>
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

  defp battery_menu_item(%{battery: %{type: :gitea}} = assigns) do
    ~H"""
    <.menu_item href={"//#{gitea_host()}/explore/repos"} name="Gitea" is_active={@active == :gitea}>
      <.gitea_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :harbor}} = assigns) do
    ~H"""
    <.menu_item href={"//#{harbor_host()}"} name="Harbor" is_active={@active == :harbor}>
      <.harbor_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :smtp4dev}} = assigns) do
    ~H"""
    <.menu_item href={"//#{smtp4dev_host()}"} name="SMTP4Dev" is_active={@active == :smtp4dev}>
      <Heroicons.envelope class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :kiali}} = assigns) do
    ~H"""
    <.menu_item href={} name="Kiali" is_active={@active == :kiali}>
      <.kiali_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :metallb_ip_pool}} = assigns) do
    ~H"""
    <.menu_item
      navigate={~p"/ip_address_pools"}
      name="IP Address Pools"
      is_active={@active == :ip_address_pools}
    >
      <Heroicons.rectangle_group class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :trivy_operator}} = assigns) do
    ~H"""
    <.menu_item
      navigate={~p"/trivy_reports/vulnerability_report"}
      name="Security Reports"
      is_active={@active == :trivy_reports}
    >
      <Heroicons.flag class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :grafana}} = assigns) do
    ~H"""
    <.menu_item href={"//#{grafana_host()}"} name="Grafana" is_active={@active == :grafana}>
      <.grafana_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: :victoria_metrics}} = assigns) do
    ~H"""
    <.menu_item
      href={"//#{vmselect_host()}/select/0/vmui"}
      name="VM Select"
      is_active={@active == :victoria_metrics}
    >
      <.victoria_metrics_icon class={@icon_class} />
    </.menu_item>
    <.menu_item href={"//#{vmagent_host()}"} name="VM Agent" is_active={@active == :victoria_metrics}>
      <.victoria_metrics_icon class={@icon_class} />
    </.menu_item>
    """
  end

  defp battery_menu_item(%{battery: %{type: _}} = assigns), do: ~H||

  attr(:active, :string, default: nil)
  attr(:group, :any)

  attr(:icon_class, :any, default: "flex-shrink-0 -ml-1 mr-3 h-6 w-6 group")

  defp group_menu_item(%{group: :magic} = assigns) do
    ~H"""
    <.menu_item
      navigate={~p"/snapshot_apply"}
      name="Snapshot Deploys"
      is_active={@active == :kube_snapshots}
    >
      <Heroicons.rocket_launch class={@icon_class} />
    </.menu_item>
    <.menu_item navigate={~p"/timeline"} name="Timeline" is_active={@active == :timeline}>
      <Heroicons.clock class={@icon_class} />
    </.menu_item>
    <.menu_item navigate={~p"/kube/pods"} name="Kubernetes" is_active={@active == :kube_resources}>
      <Heroicons.rectangle_group class={@icon_class} />
    </.menu_item>
    <.menu_item navigate={~p"/stale"} name="Stale Deleter" is_active={@active == :stale}>
      <Heroicons.clock class={@icon_class} />
    </.menu_item>
    <.menu_item
      navigate={~p"/deleted_resources"}
      name="Deleted Resources"
      is_active={@active == :deleted}
    >
      <Heroicons.trash class={@icon_class} />
    </.menu_item>
    <.menu_item
      navigate={~p"/system_batteries"}
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

  defp group_menu_item(%{group: :projects} = assigns) do
    ~H"""
    <.menu_item navigate={~p"/system_projects/new"} name="New Project" is_active={@active == :new}>
      <Heroicons.plus class={@icon_class} />
    </.menu_item>
    <.menu_item navigate={~p"/system_projects"} name="Projects" is_active={@active == :projects}>
      <Heroicons.briefcase class={@icon_class} />
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

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <nav class="space-y-1">
      <.battery_menu_item :for={battery <- @batteries} battery={battery} active={@active} />
      <.group_menu_item group={@group} active={@active} />
    </nav>
    """
  end
end
