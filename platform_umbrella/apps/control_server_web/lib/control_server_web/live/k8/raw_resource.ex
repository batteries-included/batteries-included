defmodule ControlServerWeb.Live.RawResource do
  use ControlServerWeb, {:live_view, layout: :menu}

  import ControlServerWeb.ObjectDisplay

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeExt.KubeState

  require Logger

  @impl Phoenix.LiveView
  def mount(
        %{"resource_type" => rt, "namespace" => namespace, "name" => name} = params,
        _session,
        socket
      ) do
    resource_type = String.to_existing_atom(rt)
    subscribe(resource_type)

    {:ok,
     socket
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
    <.object_display object={@resource} path={@path} base_url={} />
    """
  end
end
