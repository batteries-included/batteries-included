defmodule ControlServerWeb.ServiceLive.Show do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import CommonUI.DatetimeDisplay
  import ControlServerWeb.ResourceComponents

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

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
      events: KubeState.get_events(resource),
      conditions: conditions(resource),
      status: status(resource),
      ports: ports(resource)
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
    <.page_header title={@name} back_button={%{link_type: "live_redirect", to: ~p"/kube/services"}}>
      <:menu>
        <.data_horizontal_bordered>
          <:item title="Namespace"><%= @namespace %></:item>
          <:item title="Started">
            <.relative_display time={get_in(@resource, ~w(metadata creationTimestamp))} />
          </:item>
        </.data_horizontal_bordered>
      </:menu>
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
