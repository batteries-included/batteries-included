defmodule ControlServerWeb.Live.StatefulSetShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ResourceComponents

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  require Logger

  @resource_type :stateful_set

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
    assign(socket,
      pods: KubeState.get_owned_resources(:pod, resource),
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

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@name} back_link={~p"/kube/stateful_sets"} />

    <div class="flex flex-col gap-8 mb-10">
      <div class="flex flex-wrap gap-4 mt-6">
        <.badge>
          <:item label="Total Replicas">{Map.get(@status, "replicas", 0)}</:item>
          <:item label="Available Replicas">{Map.get(@status, "availableReplicas", 0)}</:item>
          <:item label="Updated Replicas">{Map.get(@status, "updatedReplicas", 0)}</:item>
          <:item label="Generations">{Map.get(@status, "observedGeneration", 0)}</:item>
        </.badge>
      </div>

      <.panel variant="gray" title="Details">
        <.data_list>
          <:item title="Namespace">{@namespace}</:item>
          <:item title="Current Revision">
            {Map.get(@status, "currentRevision", 0)}
          </:item>
          <:item title="Started">
            <.relative_display time={get_in(@resource, ~w(metadata creationTimestamp))} />
          </:item>
        </.data_list>
      </.panel>

      <.panel title="Pods">
        <.pods_table pods={@pods} />
      </.panel>
      <.events_panel events={@events} />
      <.label_panel resource={@resource} />
    </div>
    """
  end
end
