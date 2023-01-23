defmodule ControlServerWeb.Live.OryKratosRegister do
  use ControlServerWeb, :live_view

  import KubeServices.SystemState.SummaryHosts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>Testing <%= inspect(@flow_id) %></div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_flow_id(nil)
     |> assign_new(:kratos_cookies, fn -> "" end)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"flow" => flow_id} = _params, _uri, socket) do
    {:noreply, assign_flow_id(socket, flow_id)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{} = _params, _uri, socket) do
    to = "http://#{kratos_host()}/self-service/registration/browser"

    {:noreply, redirect(socket, external: to)}
  end

  def assign_flow_id(socket, flow_id) do
    assign(socket, flow_id: flow_id)
  end

  def assign_flow_payload(socket, flow_payload) do
    assign(socket, flow_payload: flow_payload)
  end
end
