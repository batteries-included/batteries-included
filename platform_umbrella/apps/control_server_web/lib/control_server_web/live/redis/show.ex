defmodule ControlServerWeb.Live.RedisShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ActionsDropdown
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ServicesTable

  alias CommonCore.Util.Memory
  alias ControlServer.Redis
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = KubeEventCenter.subscribe(:pod)
      :ok = KubeEventCenter.subscribe(:service)
      :ok = KubeEventCenter.subscribe(:redis_failover)
    end

    {:ok,
     socket
     |> assign(:current_page, :data)
     |> assign(:page_title, "Redis Instance")}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign_timeline_installed()
     |> assign(:id, id)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:redis_instance, Redis.get_redis_instance!(id, preload: [:project]))
     |> assign(:k8_failover, k8_failover(id))
     |> assign(:k8_services, k8_services(id))
     |> assign(:k8_pods, k8_pods(id))}
  end

  defp assign_timeline_installed(socket) do
    assign(socket, :timeline_installed, SummaryBatteries.battery_installed(:timeline))
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply,
     socket
     |> assign(:k8_failover, k8_failover(socket.assigns.id))
     |> assign(:k8_services, k8_services(socket.assigns.id))
     |> assign(:k8_pods, k8_pods(socket.assigns.id))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = Redis.delete_redis_instance(socket.assigns.redis_instance)

    {:noreply, push_navigate(socket, to: ~p"/redis")}
  end

  @impl Phoenix.LiveView
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <.page_header title={"Redis Instance: #{@redis_instance.name}"} back_link={~p"/redis"}>
      <:menu>
        <.badge :if={@redis_instance.project_id}>
          <:item label="Project" navigate={~p"/projects/#{@redis_instance.project_id}/show"}>
            {@redis_instance.project.name}
          </:item>
        </.badge>
      </:menu>

      <.flex>
        <.actions_dropdown>
          <.dropdown_link navigate={edit_url(@redis_instance)} icon={:pencil}>
            Edit Redis
          </.dropdown_link>

          <.dropdown_button
            class="w-full"
            icon={:trash}
            phx-click="delete"
            data-confirm={"Are you sure you want to delete the \"#{@redis_instance.name}\" cluster?"}
          >
            Delete Redis
          </.dropdown_button>
        </.actions_dropdown>
      </.flex>
    </.page_header>

    <.grid columns={%{sm: 1, lg: 2}}>
      <.panel title="Details" variant="gray">
        <.data_list>
          <:item title="Instances">
            {@redis_instance.num_instances}
          </:item>
          <:item :if={@redis_instance.memory_limits} title="Memory Limits">
            {Memory.humanize(@redis_instance.memory_limits)}
          </:item>
          <:item title="Started">
            <.relative_display time={creation_timestamp(@k8_failover)} />
          </:item>
        </.data_list>
      </.panel>

      <.flex column class="justify-start">
        <.a variant="bordered" navigate={services_url(@redis_instance)}>Services</.a>
      </.flex>

      <.panel title="Pods" class="col-span-2">
        <.pods_table pods={@k8_pods} />
      </.panel>
    </.grid>
    """
  end

  @impl Phoenix.LiveView
  def render(%{live_action: :services} = assigns) do
    ~H"""
    <.page_header title="Services" back_link={show_url(@redis_instance)} />

    <.panel>
      <.services_table services={@k8_services} />
    </.panel>
    """
  end

  defp page_title(:show), do: "Redis Instance"
  defp page_title(:services), do: "Redis Instance Services"

  defp edit_url(redis_instance), do: ~p"/redis/#{redis_instance}/edit"
  defp show_url(redis_instance), do: ~p"/redis/#{redis_instance}/show"
  defp services_url(redis_instance), do: ~p"/redis/#{redis_instance}/services"

  defp k8_failover(id) do
    Enum.find(KubeState.get_all(:redis_failover), nil, fn pg -> id == labeled_owner(pg) end)
  end

  defp k8_pods(id) do
    Enum.filter(KubeState.get_all(:pod), fn pg -> id == labeled_owner(pg) end)
  end

  defp k8_services(id) do
    Enum.filter(KubeState.get_all(:service), fn pg -> id == labeled_owner(pg) end)
  end
end
