defmodule ControlServerWeb.Live.OryKratosFlow do
  use ControlServerWeb, :live_view

  import KubeServices.SystemState.SummaryHosts
  import ControlServerWeb.Loader
  import ControlServerWeb.Ory.Flow

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.flow_container flow_url={@flow_url} flow_id={@flow_id}>
      <.loader :if={@flow_payload == nil} />
      <%= if @flow_payload != nil do %>
        <.flow_form ui={Map.get(@flow_payload, "ui", %{})} />
      <% end %>
    </.flow_container>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_flow_id(nil)
     |> assign_flow_payload(nil)
     |> assign_flow_url("")
     |> assign_browser_url(browser_url(socket.assigns.live_action))}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"flow" => flow_id} = _params, _uri, socket) do
    {:noreply,
     socket
     |> assign_flow_id(flow_id)
     |> assign_flow_url(flow_url(socket.assigns.live_action, flow_id))}
  end

  @impl Phoenix.LiveView
  def handle_params(%{} = _params, _uri, socket) do
    {:noreply, redirect(socket, external: socket.assigns.browser_url)}
  end

  @impl Phoenix.LiveView
  def handle_event("kratos:loaded", %{} = flow, socket) do
    {:noreply, assign_flow_payload(socket, flow)}
  end

  def assign_flow_id(socket, flow_id) do
    assign(socket, flow_id: flow_id)
  end

  def assign_flow_payload(socket, flow_payload) do
    assign(socket, flow_payload: flow_payload)
  end

  def assign_browser_url(socket, browser_url) do
    assign(socket, browser_url: browser_url)
  end

  def assign_flow_url(socket, flow_url) do
    assign(socket, flow_url: flow_url)
  end

  def flow_url(page_type, flow_id)

  def flow_url(page_type, flow_id) when is_atom(page_type),
    do: "http://#{kratos_host()}/self-service/#{to_string(page_type)}/flows?id=#{flow_id}"

  def browser_url(page_type)
  def browser_url(:login), do: "http://#{kratos_host()}/self-service/login/browser"

  def browser_url(:recovery),
    do:
      "http://#{kratos_host()}/self-service/recovery/browser?return_to=http://control.127.0.0.1.ip.batteriesincl.com:4000/auth/"

  def browser_url(:verification), do: "http://#{kratos_host()}/self-service/verification/browser"
  def browser_url(:registration), do: "http://#{kratos_host()}/self-service/registration/browser"
end
