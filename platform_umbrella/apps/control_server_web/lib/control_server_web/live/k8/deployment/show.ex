defmodule ControlServerWeb.Live.DeploymentShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ResourceComponents

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  require Logger

  @resource_type :deployment

  @impl Phoenix.LiveView
  def mount(%{"name" => name, "namespace" => namespace}, _session, socket) do
    if connected?(socket) do
      :ok = KubeEventCenter.subscribe(@resource_type)
    end

    resource = get_resource!(namespace, name)

    {:ok,
     socket
     |> assign(
       current_page: :kubernetes,
       resource: resource,
       namespace: namespace,
       name: name
     )
     |> assign_subresources(resource)}
  end

  defp assign_subresources(socket, resource) do
    replicasets = KubeState.get_owned_resources(:replicaset, resource)
    pods = Enum.flat_map(replicasets, fn rs -> KubeState.get_owned_resources(:pod, rs) end)

    assign(socket,
      replicasets: replicasets,
      pods: pods,
      events: KubeState.get_events(resource),
      conditions: conditions(resource),
      status: status(resource)
    )
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

  defp deployment_facts_section(assigns) do
    ~H"""
    <.badge>
      <:item label="Namespace">{@namespace}</:item>
      <:item label="Started">
        <.relative_display time={get_in(@resource, ~w(metadata creationTimestamp))} />
      </:item>
    </.badge>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@name} back_link={~p"/kube/deployments"}>
      <.deployment_facts_section namespace={@namespace} resource={@resource} />
    </.page_header>

    <div class="flex flex-col gap-8 mb-10">
      <div class="flex flex-wrap gap-4 mt-6">
        <.badge>
          <:item label="Total Replicas">{Map.get(@status, "replicas", 0)}</:item>
          <:item label="Available Replicas">{Map.get(@status, "availableReplicas", 0)}</:item>
          <:item label="Generations">{Map.get(@status, "observedGeneration", 0)}</:item>
        </.badge>
      </div>

      <.panel title="Pods">
        <.pods_table pods={@pods} />
      </.panel>
      <.conditions_display conditions={@conditions} />
      <.events_panel events={@events} />
      <.label_panel resource={@resource} />
    </div>
    """
  end
end
