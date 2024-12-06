defmodule ControlServerWeb.Live.PodShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.ResourceComponents
  import ControlServerWeb.ResourceHTMLHelper
  import ControlServerWeb.TrivyReports.VulnerabilitiesTable

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries
  alias KubeServices.SystemState.SummaryURLs

  require Logger

  @resource_type :pod

  @impl Phoenix.LiveView
  def mount(%{"name" => name, "namespace" => namespace}, _session, socket) do
    {:ok,
     socket
     |> assign(
       current_page: :kubernetes,
       namespace: namespace,
       name: name
     )
     |> assign_logs_pid(nil)
     |> assign_logs(nil)
     |> assign_batteries_enabled()
     |> assign_resource()
     |> assign_grafana_dashboard()}
  end

  @impl Phoenix.LiveView
  def handle_params(
        %{"container" => container},
        _uri,
        %{assigns: %{live_action: :logs, name: name, namespace: namespace}} = socket
      ) do
    # If this is a logs live_action and the container name was passed
    # Get the logs
    :ok = KubeEventCenter.subscribe(@resource_type)

    {:noreply, monitor_and_assign_logs(socket, namespace, name, container)}
  end

  def handle_params(_params, _uri, %{assigns: %{live_action: :logs}} = socket) do
    # If there is no container name then we guess.
    # and redirect the user to the correct url
    container_name =
      socket.assigns.resource
      |> get_in(~w(spec containers))
      |> Enum.map(& &1["name"])
      |> List.first()

    path = resource_path(socket.assigns.resource, :logs, %{container: container_name})
    {:noreply, push_navigate(socket, to: path, replace: true)}
  end

  def handle_params(_params, _uri, %{assigns: %{live_action: :events}} = socket) do
    :ok = KubeEventCenter.subscribe(@resource_type)

    {:noreply, assign_events(socket)}
  end

  def handle_params(_params, _uri, %{assigns: %{live_action: :security}} = socket) do
    {:noreply, assign_vulnerabilities(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> assign_events()
     |> stop_logs()
     |> assign_logs(nil)}
  end

  defp assign_events(%{assigns: %{resource: resource, live_action: :events}} = socket) do
    events = KubeState.get_events(resource)
    assign(socket, events: events)
  end

  defp assign_events(socket), do: socket

  defp assign_batteries_enabled(socket) do
    assign(socket, trivy_enabled: SummaryBatteries.battery_installed(:trivy_operator))
  end

  defp assign_grafana_dashboard(%{assigns: %{resource: resource}} = socket) do
    url =
      if SummaryBatteries.battery_installed(:grafana) do
        SummaryURLs.pod_dashboard_url(resource)
      end

    assign(socket, grafana_dashboard_url: url)
  end

  defp assign_vulnerabilities(%{assigns: %{resource: resource}} = socket) do
    reports = KubeState.get_owned_resources(:aqua_vulnerability_report, resource)

    assign(socket, reports: reports)
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
    line
  end

  @impl Phoenix.LiveView
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: resource_path(socket.assigns.resource))}
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
    # re-fetch the resources from state table
    {:noreply, assign_resource(socket)}
  end

  defp assign_resource(%{assigns: %{name: name, namespace: namespace}} = socket) do
    assign(socket, resource: KubeState.get!(@resource_type, namespace, name))
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

  attr :resource, :map
  attr :namespace, :string

  def pod_facts_section(%{} = assigns) do
    ~H"""
    <.badge>
      <:item label="Namespace">{@namespace}</:item>
      <:item label="Phase">{phase(@resource)}</:item>
      <:item label="Started">
        <.relative_display time={creation_timestamp(@resource)} />
      </:item>
    </.badge>
    """
  end

  def pod_containers_section(assigns) do
    assigns = assign(assigns, :container_statuses, container_statuses(assigns.resource))

    ~H"""
    <.panel title="Containers" class="col-span-2">
      <.table id="container-status-table" rows={@container_statuses}>
        <:col :let={cs} label="Name">{Map.get(cs, "name", "")}</:col>
        <:col :let={cs} label="Image">{Map.get(cs, "image", "")}</:col>
        <:col :let={cs} label="Started"><.status_icon status={Map.get(cs, "started", false)} /></:col>
        <:col :let={cs} label="Ready"><.status_icon status={Map.get(cs, "ready", false)} /></:col>
        <:col :let={cs} label="Restart Count">
          {Map.get(cs, "restartCount", 0)}
        </:col>
        <:action :let={cs}>
          <.button
            variant="minimal"
            link={resource_path(@resource, :logs, %{container: Map.get(cs, "name", nil)})}
            icon={:document_text}
            id={"show_resource_" <> to_html_id(cs)}
          />

          <.tooltip target_id={"show_resource_" <> to_html_id(cs)}>
            Logs
          </.tooltip>
        </:action>
      </.table>
    </.panel>
    """
  end

  defp details_panel(assigns) do
    ~H"""
    <.panel title="Details" variant="gray">
      <.data_list>
        <:item title="Running Status">
          {phase(@resource)}
        </:item>
        <:item :if={service_account(@resource)} title="Account">
          {service_account(@resource)}
        </:item>
        <:item :if={node_name(@resource)} title="Node">
          {node_name(@resource)}
        </:item>
        <:item :if={pod_ip(@resource)} title="Pod IP">
          {pod_ip(@resource)}
        </:item>
        <:item :if={qos_class(@resource)} title="Quality Of Service">
          {qos_class(@resource)}
        </:item>
      </.data_list>
    </.panel>
    """
  end

  defp link_panel(assigns) do
    ~H"""
    <.flex column class="justify-start">
      <.a variant="bordered" navigate={resource_path(@resource, :events)}>Events</.a>
      <.a variant="bordered" navigate={resource_path(@resource, :labels)}>Labels/Annotations</.a>
      <.a variant="bordered" navigate={raw_resource_path(@resource)}>Raw Kubernetes</.a>
      <.a :if={@grafana_dashboard_url != nil} variant="bordered" href={@grafana_dashboard_url}>
        Grafana Dashboard
      </.a>
      <.a :if={@trivy_enabled} variant="bordered" navigate={resource_path(@resource, :security)}>
        Security Report
      </.a>
    </.flex>
    """
  end

  defp main_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={~p"/kube/pods"}>
      <.pod_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>

    <.flex column>
      <.grid columns={[sm: 1, lg: 2]}>
        <.details_panel resource={@resource} />
        <.link_panel
          resource={@resource}
          trivy_enabled={@trivy_enabled}
          grafana_dashboard_url={@grafana_dashboard_url}
        />
      </.grid>
      <.pod_containers_section resource={@resource} />
      <.conditions_display conditions={conditions(@resource)} />
    </.flex>
    """
  end

  defp events_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.pod_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>
    <.events_panel events={@events} />
    """
  end

  defp labels_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.pod_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>

    <.flex column>
      <.panel title="Labels">
        <.data_list>
          <:item :for={{key, value} <- labels(@resource)} title={key}>
            <.truncate_tooltip value={value} />
          </:item>
        </.data_list>
      </.panel>
      <.panel title="Annotations">
        <.data_list>
          <:item :for={{key, value} <- annotations(@resource)} title={key}>
            <%!--
            We have to truncate a lot here since
            annotations can be huge and we don't want to inflate page size
            --%>
            <.truncate_tooltip value={truncate(value, length: 256)} />
          </:item>
        </.data_list>
      </.panel>
    </.flex>
    """
  end

  defp security_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.pod_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>
    <.flex column>
      <.panel :for={report <- @reports} title="Vulnerability Report">
        <.flex column>
          <.grid columns={%{sm: 1, lg: 3}}>
            <.data_list>
              <:item title="Container">
                {report |> labels() |> Map.get("trivy-operator.container.name", "")}
              </:item>
              <:item title="Artifact">
                {report |> get_in(~w(report artifact repository))} ({report
                |> get_in(~w(report artifact tag))})
              </:item>
              <:item title="Registry">
                {report |> get_in(~w(report registry server))}
              </:item>
            </.data_list>
            <.data_list>
              <:item title="Critical">
                {report |> get_in(~w(report summary criticalCount))}
              </:item>
              <:item title="High">
                {report |> get_in(~w(report summary highCount))}
              </:item>
              <:item title="Medium">
                {report |> get_in(~w(report summary mediumCount))}
              </:item>
            </.data_list>

            <.data_list>
              <:item title="Scanner">
                {report |> get_in(~w(report scanner name))}
              </:item>
              <:item title="Version">
                {report |> get_in(~w(report scanner version))}
              </:item>
              <:item title="Last Updated">
                <.relative_display time={report |> get_in(~w(report scanner updateTime))} />
              </:item>
            </.data_list>
          </.grid>
          <.vulnerabilities_table rows={
            report
            |> get_in(~w(report vulnerabilities))
            |> Enum.sort_by(fn v -> Map.get(v, "severity") end)
          } />
        </.flex>
      </.panel>
      <.panel :if={@reports == []} title="No Vulnerabilities">
        <div class="text-xxl">
          No vulnerabilities found
        </div>
      </.panel>
    </.flex>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :index -> %>
        <.main_page
          resource={@resource}
          namespace={@namespace}
          name={@name}
          trivy_enabled={@trivy_enabled}
          grafana_dashboard_url={@grafana_dashboard_url}
        />
      <% :logs -> %>
        <.main_page
          resource={@resource}
          namespace={@namespace}
          name={@name}
          trivy_enabled={@trivy_enabled}
          grafana_dashboard_url={@grafana_dashboard_url}
        />
        <.logs_modal :if={@logs} resource={@resource} logs={@logs} />
      <% :events -> %>
        <.events_page resource={@resource} namespace={@namespace} name={@name} events={@events} />
      <% :labels -> %>
        <.labels_page resource={@resource} namespace={@namespace} name={@name} />
      <% :security -> %>
        <.security_page resource={@resource} namespace={@namespace} name={@name} reports={@reports} />
      <% _ -> %>
        {@live_action}
    <% end %>
    """
  end
end
