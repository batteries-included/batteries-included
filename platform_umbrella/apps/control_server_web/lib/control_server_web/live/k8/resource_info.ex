defmodule ControlServerWeb.Live.ResourceInfo do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import CommonUI.Stats
  import ControlServerWeb.ConditionsDisplay

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeExt.KubeState
  alias K8s.Resource

  require Logger

  @impl true
  def mount(
        %{"resource_type" => rt_param, "name" => name, "namespace" => namespace} = _params,
        _session,
        socket
      ) do
    resource_type = String.to_existing_atom(rt_param)
    subscribe(resource_type)

    {:ok,
     socket
     |> assign(:resource_type, resource_type)
     |> assign(:name, name)
     |> assign(:namespace, namespace)
     |> assign(:resource, resource(resource_type, namespace, name))}
  end

  defp subscribe(resource_type) do
    :ok = KubeEventCenter.subscribe(resource_type)
  end

  @impl true
  def handle_info(_unused, socket) do
    {:noreply,
     assign(
       socket,
       :resource,
       resource(socket.assigns.resource_type, socket.assigns.namespace, socket.assigns.name)
     )}
  end

  defp resource(resource_type, namespace, name) do
    KubeState.get_resource(resource_type, namespace, name)
  end

  defp label_section(assigns) do
    ~H"""
    <.section_title>Labels</.section_title>
    <.body_section>
      <.table id="labels-table" rows={Resource.labels(@resource)}>
        <:col :let={{key, _value}} label="Key"><%= key %></:col>
        <:col :let={{_key, value}} label="Value"><%= value %></:col>
      </.table>
    </.body_section>
    """
  end

  defp status_icon(%{status: status} = assigns) when status in ["true", true, :ok] do
    ~H"""
    <div class="flex text-shamrock-500 font-semi-bold">
      <div class="flex-initial">
        True
      </div>
      <div class="flex-none ml-2">
        <Heroicons.check class="h-6 w-6" />
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

  defp pod_containers(assigns) do
    container_statuses = Map.get(assigns.status, "containerStatuses", [])
    assigns = assign(assigns, :container_statuses, container_statuses)

    ~H"""
    <.body_section>
      <%= for {cs, idx} <- Enum.with_index(@container_statuses) do %>
        <.h3 class={[idx != 0 && "mt-10"]}><%= Map.get(cs, "name", "") %></.h3>
        <div class="grid grid-cols-4 gap-1">
          <div class="col-span-1 font-mono font-semibold">Image</div>
          <div class="col-span-3"><%= Map.get(cs, "image", "") %></div>
        </div>
        <div class="grid grid-cols-6 gap-1">
          <div class="font-mono font-semibold">Started</div>
          <div><.status_icon status={Map.get(cs, "started", false)} /></div>
          <div class="font-mono font-semibold">Ready</div>
          <div><.status_icon status={Map.get(cs, "ready", false)} /></div>
          <div class="font-mono font-semibold">Restart Count</div>
          <div><%= Map.get(cs, "restartCount", 0) %></div>
        </div>
      <% end %>
    </.body_section>
    """
  end

  defp conditions(assigns) do
    conds = Map.get(assigns.status, "conditions", [])
    assigns = assign(assigns, :conditions, conds)

    ~H"""
    <.body_section>
      <.conditions_display conditions={@conditions} />
    </.body_section>
    """
  end

  defp service_spec(assigns) do
    assigns =
      assigns
      |> assign(:ports, Map.get(assigns.spec, "ports", []))
      |> assign(:selector, Map.get(assigns.spec, "selector", %{}))

    ~H"""
    <.body_section>
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
    </.body_section>
    """
  end

  defp deployment_status(assigns) do
    ~H"""
    <.body_section>
      <div class="grid grid-cols-4 gap-4">
        <div>Total Replicas</div>
        <div><%= Map.get(@status, "replicas", 0) %></div>
        <div>Available Replicas</div>
        <div><%= Map.get(@status, "availableReplicas", 0) %></div>
        <div>Unavailable Replicas</div>
        <div><%= Map.get(@status, "unavailableReplicas", 0) %></div>
        <div>Generations</div>
        <div><%= Map.get(@status, "observedGeneration", 0) %></div>
      </div>
    </.body_section>
    """
  end

  defp stateful_set_status(assigns) do
    ~H"""
    <.body_section>
      <div class="grid grid-cols-6 gap-1">
        <div class="col-span-2">Current Revision</div>
        <div class="col-span-4"><%= Map.get(@status, "currentRevision", 0) %></div>
        <div class="col-span-2">Update Revision</div>
        <div class="col-span-4"><%= Map.get(@status, "currentRevision", 0) %></div>
        <div>Total Replicas</div>
        <div><%= Map.get(@status, "replicas", 0) %></div>
        <div>Available Replicas</div>
        <div><%= Map.get(@status, "availableReplicas", 0) %></div>
        <div>Generations</div>
        <div><%= Map.get(@status, "observedGeneration", 0) %></div>
        <div>Updated Replicas</div>
        <div><%= Map.get(@status, "updatedReplicas", 0) %></div>
        <div>Collisions</div>
        <div><%= Map.get(@status, "collisionCount", 0) %></div>
      </div>
    </.body_section>
    """
  end

  defp service_info_section(assigns) do
    assigns = assign(assigns, :spec, Map.get(assigns.resource, "spec", %{}))

    ~H"""
    <.section_title>Service Info</.section_title>
    <.service_spec spec={@spec} />
    """
  end

  defp pod_info_section(assigns) do
    status = Map.get(assigns.resource, "status", %{})
    assigns = assign(assigns, :status, status)

    ~H"""
    <.section_title>Container Status</.section_title>
    <.pod_containers status={@status} />
    <.section_title>Messages</.section_title>
    <.conditions status={@status} />
    """
  end

  defp deployment_info_section(assigns) do
    status = Map.get(assigns.resource, "status", %{})
    assigns = assign(assigns, :status, status)

    ~H"""
    <.section_title>Status</.section_title>
    <.deployment_status status={@status} />
    <.section_title>Messages</.section_title>
    <.conditions status={@status} />
    """
  end

  defp stateful_set_info_section(assigns) do
    status = Map.get(assigns.resource, "status", %{})
    assigns = assign(assigns, :status, status)

    ~H"""
    <.section_title>Status</.section_title>
    <.stateful_set_status status={@status} />
    """
  end

  defp info_section(assigns) do
    ~H"""
    <%= case @resource_type do %>
      <% :pod -> %>
        <.pod_info_section resource={@resource} />
      <% :service -> %>
        <.service_info_section resource={@resource} />
      <% :deployment -> %>
        <.deployment_info_section resource={@resource} />
      <% :stateful_set -> %>
        <.stateful_set_info_section resource={@resource} />
      <% _ -> %>
        <%= inspect(@resource) %>
    <% end %>
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

  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.layout group={:magic} active={@resource_type}>
      <:title>
        <.title>Kube Status</.title>
      </:title>
      <.banner_section name={@name} namespace={@namespace} />
      <.info_section resource_type={@resource_type} resource={@resource} />
      <.label_section resource={@resource} />
    </.layout>
    """
  end
end
