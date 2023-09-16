defmodule ControlServerWeb.Live.ResourceInfo do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  import CommonUI.Link
  import CommonUI.Modal
  import CommonUI.RoundedLabel
  import CommonUI.Stats
  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ResourceURL

  alias EventCenter.KubeState, as: KubeEventCenter
  alias K8s.Resource
  alias KubeServices.KubeState

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"resource_type" => rt_param, "name" => name, "namespace" => namespace} = _params, _session, socket) do
    resource_type = String.to_existing_atom(rt_param)
    subscribe(resource_type)
    resource = resource!(resource_type, namespace, name)

    {:ok,
     socket
     |> assign_resource(resource)
     |> assign_resource_type(resource_type)
     |> assign_namespace(namespace)
     |> assign_name(name)
     |> assign_logs(nil)
     |> assign_subresources(subresources(resource_type, resource))}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"log" => "true", "namespace" => namespace, "name" => name, "container" => container}, _uri, socket) do
    {:noreply, monitor_and_assign_logs(socket, namespace, name, container)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"log" => "true", "namespace" => _, "name" => _}, _uri, socket) do
    container_name =
      socket.assigns.resource
      |> get_in(~w(spec containers))
      |> Enum.map(& &1["name"])
      |> List.first()

    url = resource_show_url(socket.assigns.resource, %{"log" => true, "container" => container_name})

    {:noreply, push_navigate(socket, to: url, replace: true)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> stop_logs()
     |> assign_logs(nil)}
  end

  def assign_resource(socket, resource) do
    assign(socket, resource: resource)
  end

  def assign_namespace(socket, namespace) do
    assign(socket, namespace: namespace)
  end

  def assign_name(socket, name) do
    assign(socket, name: name)
  end

  def assign_resource_type(socket, resource_type) do
    assign(socket, resource_type: resource_type)
  end

  def assign_logs(socket, nil) do
    assign(socket, logs: nil)
  end

  def assign_logs(socket, logs) do
    assign(socket, logs: format_logs(logs))
  end

  def assign_logs_pid(socket, pid) do
    assign(socket, logs_pid: pid)
  end

  defp format_logs(logs) do
    Enum.map(logs, &format_log/1)
  end

  defp format_log(line) do
    # TODO(@artokun) improve formatting
    line
  end

  defp subscribe(resource_type) do
    :ok = KubeEventCenter.subscribe(resource_type)
  end

  defp assign_subresources(socket, sub_resources) do
    Enum.reduce(sub_resources, socket, fn {key, value}, socket ->
      assign(socket, key, value)
    end)
  end

  defp subresources(:deployment = _resource_type, resource) do
    replicasets = owned_resources(resource, :replicaset)
    pods = Enum.flat_map(replicasets, fn rs -> owned_resources(rs, :pod) end)

    [
      replicasets: replicasets,
      pods: pods,
      events: events(resource),
      conditions: conditions(resource),
      status: status(resource)
    ]
  end

  defp subresources(:stateful_set = _resource_type, resource) do
    [
      pods: owned_resources(resource, :pod),
      events: events(resource),
      conditions: conditions(resource),
      status: status(resource)
    ]
  end

  defp subresources(_resource_type, resource) do
    [
      events: events(resource),
      conditions: conditions(resource),
      status: status(resource)
    ]
  end

  defp owned_resources(resource, wanted_type) do
    uid = get_in(resource, ~w|metadata uid|)
    KubeState.get_owned_resources(wanted_type, [uid])
  end

  defp events(resource) do
    uid = get_in(resource, ~w|metadata uid|)
    KubeState.get_events(uid)
  end

  defp conditions(resource) do
    get_in(resource, ~w|status conditions|) || []
  end

  defp status(resource) do
    get_in(resource, ["status"])
  end

  @impl Phoenix.LiveView
  def handle_info({:pod_log, line}, socket) do
    case socket.assigns.logs do
      nil ->
        {:noreply, socket}

      [_ | _] = logs ->
        {:noreply, assign_logs(socket, logs ++ [line])}

      _ ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    # re-fetch the resources
    resource =
      resource!(socket.assigns.resource_type, socket.assigns.namespace, socket.assigns.name)

    subs = subresources(socket.assigns.resource_type, resource)

    {:noreply,
     socket
     |> assign_resource(resource)
     |> assign_subresources(subs)}
  end

  defp resource!(resource_type, namespace, name) do
    KubeState.get!(resource_type, namespace, name)
  end

  defp stop_logs(%{assigns: assigns} = socket) do
    case Map.get(assigns, :logs_pid, nil) do
      nil ->
        socket

      pid ->
        _ = KubeServices.PodLogs.stop(pid)
        socket
    end
  end

  defp monitor_and_assign_logs(socket, namespace, name, container) do
    {:ok, logs_pid, logs} =
      KubeServices.PodLogs.monitor(
        namespace: namespace,
        name: name,
        container: container,
        target: self(),
        tailLines: 25
      )

    socket
    |> assign_logs(logs)
    |> assign_logs_pid(logs_pid)
  end

  defp label_section(assigns) do
    ~H"""
    <.h2>Labels</.h2>
    <div class="my-5">
      <.rounded_label :for={{key, value} <- Resource.labels(@resource)} class={label_class(key)}>
        <%= "#{key}=#{value}" %>
      </.rounded_label>
    </div>
    """
  end

  defp label_class(key) do
    cond do
      String.starts_with?(key, "battery") ->
        "bg-pink-400 text-white"

      String.contains?(key, "kubernetes.io") ->
        "bg-astral-400 text-gray"

      true ->
        "bg-white text-gray"
    end
  end

  defp status_icon(%{status: status} = assigns) when status in ["true", true, :ok] do
    ~H"""
    <div class="flex text-shamrock-700">
      <div class="flex-initial">
        True
      </div>
      <div class="flex-none ml-2">
        <Heroicons.check_circle class="h-6 w-6" />
      </div>
    </div>
    """
  end

  defp status_icon(assigns) do
    ~H"""
    <div class="flex text-heath-300 font-semi-bold">
      <div class="flex-initial">
        False
      </div>
      <div class="flex-none ml-2">
        <Heroicons.x_mark class="h-6 w-6" />
      </div>
    </div>
    """
  end

  defp pod_facts_section(%{phase: _} = assigns) do
    ~H"""
    <.data_list>
      <:item title="Phase"><%= @phase %></:item>
      <:item title="Service Account"><%= @service_account %></:item>
      <:item title="Start Time"><%= @start_time %></:item>
    </.data_list>
    """
  end

  defp pod_facts_section(assigns) do
    assigns
    |> assign_new(:phase, fn -> get_in(assigns.resource, ~w|status phase|) end)
    |> assign_new(:start_time, fn -> get_in(assigns.resource, ~w|status startTime|) end)
    |> assign_new(:service_account, fn -> get_in(assigns.resource, ~w|spec serviceAccount|) end)
    |> pod_facts_section()
  end

  defp pod_containers_section(assigns) do
    container_statuses = Map.get(assigns.status, "containerStatuses", [])
    init_container_statuses = Map.get(assigns.status, "initContainerStatuses", [])
    all_containers = Enum.concat(init_container_statuses, container_statuses)

    assigns = assign(assigns, :container_statuses, all_containers)

    ~H"""
    <.card class="py-0">
      <.table id="pod-containers" rows={@container_statuses}>
        <:col :let={cs} label="Name"><%= Map.get(cs, "name", "") %></:col>
        <:col :let={cs} label="Image"><%= Map.get(cs, "image", "") %></:col>
        <:col :let={cs} label="Started"><.status_icon status={Map.get(cs, "started", false)} /></:col>
        <:col :let={cs} label="Ready"><.status_icon status={Map.get(cs, "ready", false)} /></:col>
        <:col :let={cs} label="Restart Count">
          <%= Map.get(cs, "restartCount", 0) %>
        </:col>
        <:action :let={cs}>
          <.a
            patch={
              resource_show_url(@resource, %{"log" => true, "container" => Map.get(cs, "name", "")})
            }
            replace={true}
            variant="styled"
          >
            Stream Log
          </.a>
        </:action>
      </.table>
    </.card>
    """
  end

  defp service_spec(assigns) do
    assigns =
      assigns
      |> assign(:ports, Map.get(assigns.spec, "ports", []))
      |> assign(:selector, Map.get(assigns.spec, "selector", %{}))

    ~H"""
    <.card>
      <.h3>Selector</.h3>
      <div class="grid grid-cols-2 gap-1">
        <%= for {key, value} <- @selector do %>
          <div class="font-mono font-semibold"><%= key %></div>
          <div><%= value %></div>
        <% end %>
      </div>

      <.h3 class="mt-10">Ports</.h3>
      <.table id="ports-table" rows={@ports}>
        <:col :let={port} label="Name"><%= Map.get(port, "name", "") %></:col>
        <:col :let={port} label="Port"><%= Map.get(port, "port", "") %></:col>
        <:col :let={port} label="Target Port"><%= Map.get(port, "targetPort", "") %></:col>
        <:col :let={port} label="Protocol"><%= Map.get(port, "protocol", "") %></:col>
      </.table>
    </.card>
    """
  end

  defp events_section(%{events: events} = assigns) when events == [] do
    ~H"""
    <.h2 class="flex items-center">
      Events - <span class="text-base text-gray-500 pt-1 pl-3">No new events!</span>
    </.h2>
    """
  end

  defp events_section(assigns) do
    ~H"""
    <.h2>Events</.h2>
    <.table rows={@events}>
      <:col :let={event} label="Reason"><%= get_in(event, ~w(reason)) %></:col>
      <:col :let={event} label="Message"><%= event |> get_in(~w(message)) |> truncate() %></:col>
      <:col :let={event} label="Type"><%= get_in(event, ~w(type)) %></:col>
      <:col :let={event} label="First Time">
        <%= Timex.format!(event_time(event), "{RFC822z}") %>
      </:col>
      <:col :let={event} label="Count"><%= get_in(event, ~w(count)) %></:col>
    </.table>
    """
  end

  defp event_time(event) do
    event
    |> get_in(~w(firstTimestamp))
    |> Timex.parse!("{ISO:Extended:Z}")
  end

  defp deployment_status(assigns) do
    ~H"""
    <.data_list>
      <:item title="Total Replicas"><%= Map.get(@status, "replicas", 0) %></:item>
      <:item title="Available Replicas"><%= Map.get(@status, "availableReplicas", 0) %></:item>
      <:item title="Unavailable Replicas"><%= Map.get(@status, "unavailableReplicas", 0) %></:item>
      <:item title="Generations"><%= Map.get(@status, "Generations", 0) %></:item>
    </.data_list>
    """
  end

  defp stateful_set_status(assigns) do
    ~H"""
    <.data_list>
      <:item title="Current Revision"><%= Map.get(@status, "currentRevision", 0) %></:item>
      <:item title="Update Revision"><%= Map.get(@status, "updateRevision", 0) %></:item>
      <:item title="Total Replicas"><%= Map.get(@status, "replicas", 0) %></:item>
      <:item title="Available Replicas"><%= Map.get(@status, "availableReplicas", 0) %></:item>
      <:item title="Unavailable Replicas"><%= Map.get(@status, "unavailableReplicas", 0) %></:item>
      <:item title="Updated Replicas"><%= Map.get(@status, "updatedReplicas", 0) %></:item>
      <:item title="Generations"><%= Map.get(@status, "Generations", 0) %></:item>
    </.data_list>
    """
  end

  defp service_info_section(assigns) do
    assigns = assign(assigns, :spec, Map.get(assigns.resource, "spec", %{}))

    ~H"""
    <.label_section resource={@resource} />
    <.h2>Service Info</.h2>
    <.service_spec spec={@spec} />
    """
  end

  defp pod_info_section(assigns) do
    ~H"""
    <.pod_facts_section resource={@resource} />
    <.label_section resource={@resource} />
    <.h2>Container Status</.h2>
    <.pod_containers_section status={@status} resource={@resource} />
    <.conditions_display conditions={@conditions} />
    <.events_section events={@events} />
    """
  end

  defp deployment_info_section(assigns) do
    ~H"""
    <.deployment_status status={@status} />
    <.label_section resource={@resource} />
    <.conditions_display conditions={@conditions} />
    <.events_section events={@events} />
    <.h2>Pods</.h2>
    <.pods_table pods={@pods} />
    """
  end

  defp stateful_set_info_section(assigns) do
    ~H"""
    <.stateful_set_status status={@status} />
    <.label_section resource={@resource} />
    <.events_section events={@events} />
    <.h2>Pods</.h2>
    <.pods_table pods={@pods} />
    """
  end

  defp banner_section(assigns) do
    ~H"""
    <.stats>
      <.stat>
        <.stat_title>Name</.stat_title>
        <.stat_value><%= @name %></.stat_value>
      </.stat>
      <.stat>
        <.stat_title>Namespace</.stat_title>
        <.stat_value><%= @namespace %></.stat_value>
      </.stat>
    </.stats>
    """
  end

  defp logs_modal(assigns) do
    ~H"""
    <div :if={@logs != nil}>
      <.modal
        show={true}
        id="resource-logs"
        on_cancel={JS.patch(resource_show_url(@resource), replace: true)}
      >
        <:title>
          <.h2 variant="fancy">Logs</.h2>
        </:title>
        <div
          id="scroller"
          style="max-height: 70vh"
          class="bg-astral-900 min-h-16 max-h-full rounded"
          phx-hook="ResourceLogsModal"
        >
          <code class="block p-3 text-white overflow-x-scroll">
            <p :for={line <- @logs || []} class="mb-3 whitespace-normal leading-none">
              <span class="px-2 inline-block bg-astral-400 bg-opacity-20 font-mono text-sm">
                <%= line %>
              </span>
            </p>
            <div id="anchor"></div>
          </code>
        </div>
      </.modal>
    </div>
    """
  end

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.h1>
      <span class="capitalize">
        <%= @resource_type %>
      </span>
      <:sub_header><%= @name %></:sub_header>
    </.h1>
    <.banner_section name={@name} namespace={@namespace} />

    <%= case @resource_type do %>
      <% :pod -> %>
        <.pod_info_section
          resource={@resource}
          events={@events}
          status={@status}
          conditions={@conditions}
        />
      <% :service -> %>
        <.service_info_section resource={@resource} events={@events} />
      <% :deployment -> %>
        <.deployment_info_section
          resource={@resource}
          pods={@pods}
          status={@status}
          conditions={@conditions}
          events={@events}
        />
      <% :stateful_set -> %>
        <.stateful_set_info_section
          resource={@resource}
          pods={@pods}
          status={@status}
          events={@events}
        />
      <% _ -> %>
        <%= inspect(@resource) %>
    <% end %>
    <.logs_modal resource={@resource} logs={@logs} />
    """
  end
end
