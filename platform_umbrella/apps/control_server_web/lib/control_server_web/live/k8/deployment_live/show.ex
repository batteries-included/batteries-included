defmodule ControlServerWeb.DeploymentLive.Show do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ResourceComponents

  alias ControlServerWeb.Resource
  alias EventCenter.KubeState, as: KubeEventCenter

  require Logger

  @resource_type :deployment

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
       name: name
     )
     |> assign_subresources(resource)}
  end

  defp assign_subresources(socket, resource) do
    assign(socket,
      replicasets: Resource.replicasets(resource),
      pods: Resource.pods_from_replicasets(resource),
      events: Resource.events(resource),
      conditions: Resource.conditions(resource),
      status: Resource.status(resource)
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
    Resource.get_resource!(@resource_type, namespace, name)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@name} back_button={%{link_type: "live_redirect", to: ~p"/kube/deployments"}}>
      <:right_side>
        <div class={["ml-8 flex-1 flex justify-start items-center"]}>
          <.data_horizontal_bordered>
            <:item title="Namespace"><%= @namespace %></:item>
          </.data_horizontal_bordered>
        </div>
      </:right_side>
    </.page_header>

    <div class="flex flex-col gap-8 mb-10">
      <.data_pills class="mt-8">
        <:item title="Total Replicas"><%= Map.get(@status, "replicas", 0) %></:item>
        <:item title="Available Replicas"><%= Map.get(@status, "availableReplicas", 0) %></:item>
        <:item title="Unavailable Replicas"><%= Map.get(@status, "unavailableReplicas", 0) %></:item>
        <:item title="Generations"><%= Map.get(@status, "Generations", 0) %></:item>
      </.data_pills>
      <.panel title="Pods">
        <.pods_table pods={@pods} />
      </.panel>
      <.conditions_display conditions={@conditions} />
      <.events_section events={@events} />
      <.label_section resource={@resource} />
    </div>
    """
  end
end
