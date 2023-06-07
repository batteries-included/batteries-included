defmodule ControlServerWeb.LeftMenu do
  use ControlServerWeb, :html

  alias CommonCore.Batteries.SystemBattery

  import CommonUI.Icons.Database
  import CommonUI.Icons.Batteries
  import CommonUI.Icons.Devtools
  import CommonUI.Icons.Monitoring
  import CommonUI.Icons.Network
  import CommonUI.Icons.Notebook
  import CommonUI.Icons.Rook
  import CommonUI.Icons.CNCF
  import KubeServices.SystemState.SummaryHosts

  attr :icon_class, :string, default: "h-5"
  attr :page_group, :atom, required: true
  attr :page_detail_type, :atom, required: true
  attr :installed_batteries, :list, default: []
  attr :rest, :global

  def left_menu(assigns) do
    ~H"""
    <aside
      class="menu-container sticky shadow-lg bg-white"
      x-data="{'show': false, 'tab': 'data'}"
      x-on:keydown.escape="show = false"
      {@rest}
    >
      <div class="menu-items w-36 h-full flex flex-col overflow-x-hidden shadow-lg text-gray-600 bg-white">
        <.main_menu_item navigate={~p{/}}>
          <:icon><Heroicons.home class={@icon_class} /></:icon>
          <:label>Home</:label>
        </.main_menu_item>

        <.main_menu_item group={:data} page_group={@page_group}>
          <:icon><Heroicons.circle_stack class={@icon_class} /></:icon>
          <:label>Datastores</:label>
        </.main_menu_item>

        <.main_menu_item group={:devtools} page_group={@page_group}>
          <:icon><.devtools_icon class={@icon_class} /></:icon>
          <:label>Devtools</:label>
        </.main_menu_item>

        <.main_menu_item group={:monitoring} page_group={@page_group}>
          <:icon><Heroicons.chart_bar class={@icon_class} /></:icon>
          <:label>Monitoring</:label>
        </.main_menu_item>

        <.main_menu_item group={:net_sec} page_group={@page_group}>
          <:icon><.net_sec_icon class={@icon_class} /></:icon>
          <:label>Net/Security</:label>
        </.main_menu_item>

        <.main_menu_item group={:ml} page_group={@page_group}>
          <:icon><Heroicons.beaker class={@icon_class} /></:icon>
          <:label>ML</:label>
        </.main_menu_item>

        <.main_menu_item group={:kube} page_group={@page_group}>
          <:icon><.kubernetes_logo class={@icon_class} /></:icon>
          <:label>Kubernetes</:label>
        </.main_menu_item>

        <.main_menu_item group={:magic} page_group={@page_group}>
          <:icon><Heroicons.sparkles class={@icon_class} /></:icon>
          <:label>Magic</:label>
        </.main_menu_item>
      </div>

      <.menu_detail
        page_group={@page_group}
        page_detail_type={@page_detail_type}
        installed_batteries={batteries_for_group(@installed_batteries || [], :data)}
        group={:data}
      />

      <.menu_detail
        page_group={@page_group}
        page_detail_type={@page_detail_type}
        installed_batteries={batteries_for_group(@installed_batteries || [], :devtools)}
        group={:devtools}
      />

      <.menu_detail
        page_group={@page_group}
        page_detail_type={@page_detail_type}
        installed_batteries={batteries_for_group(@installed_batteries || [], :monitoring)}
        group={:monitoring}
      />

      <.menu_detail
        page_group={@page_group}
        page_detail_type={@page_detail_type}
        installed_batteries={batteries_for_group(@installed_batteries || [], :net_sec)}
        group={:net_sec}
      />

      <.menu_detail
        page_group={@page_group}
        page_detail_type={@page_detail_type}
        installed_batteries={batteries_for_group(@installed_batteries || [], :ml)}
        group={:ml}
      />

      <.menu_detail
        page_group={@page_group}
        page_detail_type={@page_detail_type}
        installed_batteries={[]}
        group={:kube}
      />

      <.menu_detail
        page_group={@page_group}
        page_detail_type={@page_detail_type}
        installed_batteries={batteries_for_group(@installed_batteries || [], :magic)}
        group={:magic}
      />
    </aside>
    """
  end

  attr :is_active, :boolean, default: false
  attr :navigate, :string
  attr :group, :atom
  attr :page_group, :atom
  attr :rest, :global
  slot :label
  slot :icon

  def main_menu_item(%{navigate: nav} = assigns) when not is_nil(nav) do
    ~H"""
    <.a navigate={@navigate} variant="unstyled" class={main_menu_class(@is_active)} {@rest}>
      <div class="mt-2 mb-1 mx-auto">
        <%= render_slot(@icon) %>
      </div>
      <div class="mx-auto text-center">
        <%= render_slot(@label) %>
      </div>
    </.a>
    """
  end

  def main_menu_item(assigns) do
    ~H"""
    <.button
      variant="unstyled"
      x-on:click={menu_item_click(@group)}
      x-on:click.stop
      class={main_menu_class(@is_active)}
      {@rest}
    >
      <div class="mt-2 mb-1 mx-auto">
        <%= render_slot(@icon) %>
      </div>
      <div class="mx-auto text-center">
        <%= render_slot(@label) %>
      </div>
    </.button>
    """
  end

  attr :installed_batteries, :list, required: true
  attr :group, :atom, required: true
  attr :page_group, :atom, required: true
  attr :page_detail_type, :atom, required: true

  def menu_detail(assigns) do
    ~H"""
    <div
      class="menu-detail bg-white shadow-lg px-4 py-3 flex flex-col w-72 absolute ease-in-out duration-500 space-y-4"
      x-bind:class={"{'active': show && tab == '#{@group}' }"}
      x-on:click.away="show = false"
      x-on:click.stop
      x-cloak
      x-transition
    >
      <.group_detail_item
        group={@group}
        page_detail_type={@page_detail_type}
        page_group={@page_group}
      />
      <.battery_detail_item
        :for={battery <- @installed_batteries}
        battery={battery}
        page_detail_type={@page_detail_type}
        page_group={@page_group}
      />
    </div>
    """
  end

  attr :group, :atom, required: true
  attr :page_group, :atom, required: true
  attr :page_detail_type, :atom, required: true
  attr :icon_class, :any, default: "mx-2 h-5 w-auto group my-1"

  def group_detail_item(%{group: :data} = assigns) do
    ~H"""
    <.h4>Datastores</.h4>

    <.detail_menu_item
      navigate={~p"/batteries/#{@group}"}
      name="Batteries"
      is_active={@page_detail_type == :batteries && @page_group == @group}
    >
      <.batteries_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  def group_detail_item(%{group: :devtools} = assigns) do
    ~H"""
    <.h4>Devtools</.h4>

    <.detail_menu_item
      navigate={~p"/batteries/#{@group}"}
      name="Batteries"
      is_active={@page_detail_type == :batteries && @page_group == @group}
    >
      <.batteries_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  def group_detail_item(%{group: :monitoring} = assigns) do
    ~H"""
    <.h4>Monitoring</.h4>

    <.detail_menu_item
      navigate={~p"/batteries/#{@group}"}
      name="Batteries"
      is_active={@page_detail_type == :batteries && @page_group == @group}
    >
      <.batteries_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  def group_detail_item(%{group: :ml} = assigns) do
    ~H"""
    <.h4>Machine Learning</.h4>

    <.detail_menu_item
      navigate={~p"/batteries/#{@group}"}
      name="Batteries"
      is_active={@page_detail_type == :batteries && @page_group == @group}
    >
      <.batteries_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  def group_detail_item(%{group: :net_sec} = assigns) do
    ~H"""
    <.h4>Networking/Security</.h4>

    <.detail_menu_item
      navigate={~p"/batteries/#{@group}"}
      name="Batteries"
      is_active={@page_detail_type == :batteries && @page_group == @group}
    >
      <.batteries_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  def group_detail_item(%{group: :kube} = assigns) do
    ~H"""
    <.h4>Kubernetes</.h4>

    <.detail_menu_item navigate={~p"/kube/pods"} name="Pods" is_active={@page_detail_type == :pods}>
      <Heroicons.rectangle_group class={@icon_class} />
    </.detail_menu_item>
    <.detail_menu_item
      navigate={~p"/kube/deployments"}
      name="Deployments"
      is_active={@page_detail_type == :deployments}
    >
      <Heroicons.square_3_stack_3d class={@icon_class} />
    </.detail_menu_item>
    <.detail_menu_item
      navigate={~p"/kube/stateful_sets"}
      name="Stateful Sets"
      is_active={@page_detail_type == :stateful_sets}
    >
      <Heroicons.rectangle_stack class={@icon_class} />
    </.detail_menu_item>
    <.detail_menu_item
      navigate={~p"/kube/services"}
      name="Services"
      is_active={@page_detail_type == :services}
    >
      <Heroicons.phone_arrow_down_left class={@icon_class} />
    </.detail_menu_item>
    <.detail_menu_item navigate={~p"/kube/nodes"} name="Nodes" is_active={@page_detail_type == :nodes}>
      <Heroicons.server class={@icon_class} />
    </.detail_menu_item>
    """
  end

  def group_detail_item(%{group: :magic} = assigns) do
    ~H"""
    <.h4>Magic</.h4>

    <.detail_menu_item
      navigate={~p"/batteries/magic"}
      name="Batteries"
      is_active={@page_detail_type == :batteries}
    >
      <.batteries_icon class={@icon_class} />
    </.detail_menu_item>
    <.detail_menu_item
      navigate={~p"/snapshot_apply"}
      name="Deploys"
      is_active={@page_detail_type == :kube_snapshots}
    >
      <Heroicons.rocket_launch class={@icon_class} />
    </.detail_menu_item>
    <.detail_menu_item
      navigate={~p"/timeline"}
      name="Timeline"
      is_active={@page_detail_type == :timeline}
    >
      <Heroicons.clock class={@icon_class} />
    </.detail_menu_item>

    <.h4>Delete</.h4>
    <.detail_menu_item
      navigate={~p"/stale"}
      name="Stale Delete Queue"
      is_active={@page_detail_type == :stale}
    >
      <Heroicons.clock class={@icon_class} />
    </.detail_menu_item>
    <.detail_menu_item
      navigate={~p"/deleted_resources"}
      name="Deleted Resources"
      is_active={@page_detail_type == :deleted}
    >
      <Heroicons.trash class={@icon_class} />
    </.detail_menu_item>

    <.h4>Batteries</.h4>
    <.detail_menu_item
      navigate={~p"/system_batteries"}
      name="Installed Batteries"
      is_active={@page_detail_type == :installed_batteries}
    >
      <Heroicons.battery_100 class={@icon_class} />
    </.detail_menu_item>
    """
  end

  def group_detail_item(assigns) do
    ~H"""
    <.detail_menu_item
      navigate={~p"/batteries/#{@group}"}
      name="Batteries"
      is_active={@page_detail_type == :batteries && @page_group == @group}
    >
      <.batteries_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  attr :icon_class, :any, default: "mx-2 h-5 w-auto group my-1"
  attr :battery, :any, default: %{type: :unknown}
  attr :page_detail_type, :atom, required: true
  attr :page_group, :atom, required: true

  defp battery_detail_item(%{battery: %{type: :postgres}} = assigns) do
    ~H"""
    <.h4>Postgres</.h4>
    <.detail_menu_item
      navigate={~p"/postgres"}
      name="Postgres Clusters"
      is_active={@page_detail_type == :postgres_clusters}
    >
      <Heroicons.circle_stack class={@icon_class} />
    </.detail_menu_item>

    <.detail_menu_item
      navigate={~p"/postgres/new"}
      name="New PostgreSQL"
      is_active={@page_detail_type == :new_cluster}
    >
      <Heroicons.plus_circle class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :redis}} = assigns) do
    ~H"""
    <.h4>Redis</.h4>
    <.detail_menu_item
      navigate={~p"/redis"}
      name="Redis Clusters"
      is_active={@page_detail_type == :redis}
    >
      <.redis_icon class={@icon_class} />
    </.detail_menu_item>

    <.detail_menu_item
      navigate={~p"/redis"}
      name="New Redis"
      is_active={@page_detail_type == :new_redis}
    >
      <Heroicons.plus_circle class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :rook}} = assigns) do
    ~H"""
    <.detail_menu_item navigate={~p"/ceph"} name="Ceph" is_active={@page_detail_type == :rook}>
      <.ceph_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :knative_serving}} = assigns) do
    ~H"""
    <.h4>Knative  Serverless</.h4>
    <.detail_menu_item
      navigate={~p"/knative/services"}
      name="Knative Services"
      is_active={@page_detail_type == :knative_serving}
    >
      <Heroicons.square_3_stack_3d solid class={@icon_class} />
    </.detail_menu_item>

    <.detail_menu_item
      navigate={~p"/knative/services/new"}
      name="New Serverless Service"
      is_active={@page_detail_type == :new_knative}
    >
      <Heroicons.plus_circle class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :notebooks}} = assigns) do
    ~H"""
    <.detail_menu_item
      navigate={~p"/notebooks"}
      name="Notebooks"
      is_active={@page_detail_type == :notebooks}
    >
      <.notebook_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :gitea}} = assigns) do
    ~H"""
    <.detail_menu_item
      href={"//#{gitea_host()}/explore/repos"}
      name="Gitea"
      is_active={@page_detail_type == :gitea}
    >
      <.gitea_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :harbor}} = assigns) do
    ~H"""
    <.detail_menu_item
      href={"//#{harbor_host()}"}
      name="Harbor"
      is_active={@page_detail_type == :harbor}
    >
      <.harbor_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :smtp4dev}} = assigns) do
    ~H"""
    <.detail_menu_item
      href={"//#{smtp4dev_host()}"}
      name="SMTP4Dev"
      is_active={@page_detail_type == :smtp4dev}
    >
      <Heroicons.envelope class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :kiali}} = assigns) do
    ~H"""
    <.detail_menu_item href={} name="Kiali" is_active={@page_detail_type == :kiali}>
      <.kiali_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :metallb}} = assigns) do
    ~H"""
    <.h4>MetalLB</.h4>
    <.detail_menu_item
      navigate={~p"/ip_address_pools"}
      name="IP Address Pools"
      is_active={@page_detail_type == :ip_address_pools}
    >
      <Heroicons.rectangle_group class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :trivy_operator}} = assigns) do
    ~H"""
    <.h4>Trivy</.h4>

    <.detail_menu_item
      navigate={~p"/trivy_reports/vulnerability_report"}
      name="Vulnerability Report"
      is_active={@page_detail_type == :vulnerability_report}
    >
      <Heroicons.flag class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :grafana}} = assigns) do
    ~H"""
    <.detail_menu_item
      href={"//#{grafana_host()}"}
      name="Grafana"
      is_active={@page_detail_type == :grafana}
    >
      <.grafana_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :victoria_metrics}} = assigns) do
    ~H"""
    <.detail_menu_item
      href={"//#{vmselect_host()}/select/0/vmui"}
      name="VM Select"
      is_active={@page_detail_type == :victoria_metrics}
    >
      <.victoria_metrics_icon class={@icon_class} />
    </.detail_menu_item>
    <.detail_menu_item
      href={"//#{vmagent_host()}"}
      name="VM Agent"
      is_active={@page_detail_type == :victoria_metrics}
    >
      <.victoria_metrics_icon class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: :sso}} = assigns) do
    ~H"""
    <.h4>Keycloak</.h4>
    <.detail_menu_item
      navigate={~p"/keycloak/realms"}
      name="Realms"
      is_active={@page_detail_type == :realms}
    >
      <Heroicons.key class={@icon_class} />
    </.detail_menu_item>
    """
  end

  defp battery_detail_item(%{battery: %{type: _}} = assigns), do: ~H||

  attr :navigate, :string
  attr :href, :string
  attr :name, :string, required: true
  attr :is_active, :boolean, default: false
  slot :inner_block

  def detail_menu_item(%{navigate: nav} = assigns) when not is_nil(nav) do
    ~H"""
    <.a navigate={@navigate} class={menu_detail_class(@is_active)}>
      <span class="inline-block my-auto"><%= render_slot(@inner_block) %></span>
      <%= truncate(@name) %>
    </.a>
    """
  end

  def detail_menu_item(%{href: href} = assigns) when not is_nil(href) do
    ~H"""
    <.a href={@href} class={menu_detail_class(@is_active)}>
      <span class="inline-block"><%= render_slot(@inner_block) %></span>
      <%= truncate(@name) %>
    </.a>
    """
  end

  defp menu_item_click(nil = _show_var), do: nil
  defp menu_item_click(group) when is_atom(group), do: menu_item_click(Atom.to_string(group))

  defp menu_item_click(group) when is_binary(group),
    do: "show = (tab === '#{group}' ? !show : true); tab = '#{group}';"

  defp main_menu_class(false = _is_active),
    do:
      "relative block w-full border-b text-center hover:text-pink-500 flex flex-col p-3 bg-white"

  defp main_menu_class(true = _is_active), do: build_class(["active", main_menu_class(false)])

  defp batteries_for_group(batteries, group) do
    Enum.filter(batteries, fn %SystemBattery{} = bat -> bat.group == group end)
  end

  defp menu_detail_class(true = _is_active),
    do: "text-pink-500 whitespace-nowrap flex hover:under-line"

  defp menu_detail_class(false = _is_active),
    do: "whitespace-nowrap flex hover:under-line hover:text-pink-500"
end
