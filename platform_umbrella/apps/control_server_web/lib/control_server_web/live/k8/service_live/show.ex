defmodule ControlServerWeb.ServiceLive.Show do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.ResourceComponents

  alias ControlServerWeb.Resource
  alias EventCenter.KubeState, as: KubeEventCenter

  require Logger

  @resource_type :service

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
      events: Resource.events(resource),
      conditions: Resource.conditions(resource),
      status: Resource.status(resource),
      ports: Resource.ports(resource)
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
    <.page_header title={@name} back_button={%{link_type: "live_redirect", to: ~p"/kube/services"}}>
      <:right_side>
        <div class={["ml-8 flex-1 flex justify-between items-center"]}>
          <.data_horizontal_bordered>
            <:item title="Namespace"><%= @namespace %></:item>
          </.data_horizontal_bordered>
        </div>
      </:right_side>
    </.page_header>

    <div class="flex flex-col gap-8 mt-8">
      <.panel variant="gray" title="Ports">
        <.table :if={@ports != []} transparent id="ports-table" rows={@ports}>
          <:col :let={port} label="Name"><%= Map.get(port, "name", "") %></:col>
          <:col :let={port} label="Port"><%= Map.get(port, "port", "") %></:col>
          <:col :let={port} label="Target Port"><%= Map.get(port, "targetPort", "") %></:col>
          <:col :let={port} label="Protocol"><%= Map.get(port, "protocol", "") %></:col>
        </.table>

        <div :if={@ports == []}>No ports.</div>
      </.panel>

      <.label_section resource={@resource} />
    </div>
    """
  end
end
