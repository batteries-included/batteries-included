defmodule ControlServerWeb.Live.RawResource do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.ObjectDisplay

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"resource_type" => rt, "namespace" => namespace, "name" => name} = params, _session, socket) do
    resource_type = String.to_existing_atom(rt)
    subscribe(resource_type)

    {:ok,
     socket
     |> assign(:current_page, :kubernetes)
     |> assign(:base_url, base_url(resource_type, namespace, name))
     |> assign(:path, Map.get(params, "path", []))
     |> assign(:resource_type, resource_type)
     |> assign(:namespace, namespace)
     |> assign(:name, name)
     |> assign(:resource, resource(resource_type, namespace, name))}
  end

  defp base_url(resource_type, namespace, name) do
    ~p"/kube/raw/#{resource_type}/#{namespace}/#{name}"
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, :path, Map.get(params, "path", []))}
  end

  defp subscribe(resource_type) do
    :ok = KubeEventCenter.subscribe(resource_type)
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply,
     assign(
       socket,
       :resource,
       resource(socket.assigns.resource_type, socket.assigns.namespace, socket.assigns.name)
     )}
  end

  defp resource(resource_type, namespace, name) do
    KubeState.get!(resource_type, namespace, name)
  end

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.h1>Raw {@resource_type}</.h1>
    <.panel>
      <.object_display object={@resource} path={@path} base_url={@base_url} />
    </.panel>
    """
  end
end
