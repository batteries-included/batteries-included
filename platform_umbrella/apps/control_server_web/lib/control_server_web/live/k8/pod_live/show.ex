defmodule ControlServerWeb.PodLive.Show do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import CommonUI.DatetimeDisplay
  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.ResourceComponents
  import ControlServerWeb.ResourceHTMLHelper
  import ControlServerWeb.TrivyReports.VulnerabilitiesTable

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  require Logger

  @resource_type :pod

  @impl Phoenix.LiveView
  def mount(%{"name" => name, "namespace" => namespace}, _session, socket) do
    :ok = KubeEventCenter.subscribe(@resource_type)
    resource = get_resource!(namespace, name)

    {:ok,
     socket
     |> assign(
       current_page: :kubernetes,
       resource: resource,
       namespace: namespace,
       name: name,
       logs: nil
     )
     |> assign_subresources(resource)}
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

    url = resource_show_path(socket.assigns.resource, %{"log" => true, "container" => container_name})

    {:noreply, push_navigate(socket, to: url, replace: true)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> stop_logs()
     |> assign_logs(nil)}
  end

  def assign_logs(socket, logs) do
    assign(socket, logs: format_logs(logs))
  end

  def assign_logs_pid(socket, pid) do
    assign(socket, logs_pid: pid)
  end

  defp format_logs(logs) when is_list(logs) do
    Enum.map(logs, &format_log/1)
  end

  defp format_logs(logs), do: logs

  defp format_log(line) do
    # TODO(@artokun) improve formatting
    line
  end

  defp assign_subresources(socket, resource) do
    assign(socket,
      events: KubeState.get_events(resource),
      conditions: conditions(resource),
      status: status(resource),
      aqua_vulnerability_report: :aqua_vulnerability_report |> KubeState.get_owned_resources(resource) |> List.first()
    )
  end

  @impl Phoenix.LiveView
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: resource_show_path(socket.assigns.resource))}
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
    resource = get_resource!(socket.assigns.namespace, socket.assigns.name)

    {:noreply,
     socket
     |> assign(resource: resource)
     |> assign_subresources(resource)}
  end

  defp get_resource!(namespace, name) do
    KubeState.get!(@resource_type, namespace, name)
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

  defp security_section(assigns) do
    ~H"""
    <.panel :if={@aqua_vulnerability_report != nil} title="Vulnerabilities" class="mb-10">
      <.vulnerabilities_table rows={get_in(@aqua_vulnerability_report, ~w(report vulnerabilities))} />
    </.panel>
    """
  end

  attr :resource, :map
  attr :namespace, :string
  attr :phase, :string
  attr :service_account, :string

  def pod_facts_section(%{phase: _} = assigns) do
    ~H"""
    <.data_horizontal_bordered>
      <:item title="Namespace"><%= @namespace %></:item>
      <:item title="Phase"><%= @phase %></:item>
      <:item title="Account"><%= @service_account %></:item>
      <:item title="Started">
        <.relative_display time={get_in(@resource, ~w(metadata creationTimestamp))} />
      </:item>
    </.data_horizontal_bordered>
    """
  end

  def pod_facts_section(assigns) do
    assigns
    |> assign_new(:phase, fn -> get_in(assigns.resource, ~w|status phase|) end)
    |> assign_new(:service_account, fn -> get_in(assigns.resource, ~w|spec serviceAccount|) end)
    |> pod_facts_section()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@name} back_button={%{link_type: "live_redirect", to: ~p"/kube/pods"}}>
      <:right_side>
        <.pod_facts_section resource={@resource} namespace={@namespace} />
      </:right_side>
    </.page_header>

    <div class="flex flex-col gap-8 mb-10">
      <.pod_containers_section resource={@resource} />
      <.conditions_display conditions={@conditions} />
      <.events_section events={@events} />

      <.label_section class="mb-10" resource={@resource} />
    </div>
    <.security_section aqua_vulnerability_report={@aqua_vulnerability_report} />
    <.logs_modal resource={@resource} logs={@logs} />
    """
  end
end
