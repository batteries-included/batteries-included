defmodule ControlServerWeb.Live.OryKratosRegister do
  use ControlServerWeb, :live_view

  import KubeServices.SystemState.SummaryHosts
  import ControlServerWeb.Loader
  import ControlServerWeb.Ory.Flow

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div
      id={flow_container_id(@flow_id)}
      phx-hook="KratosFlow"
      data-flow-url={"http://#{kratos_host()}/self-service/registration/flows?"}
      data-flow-id={@flow_id}
    >
      <.loader :if={@flow_payload == nil} />
      <%= if @flow_payload != nil do %>
        <.flow_form ui={Map.get(@flow_payload, "ui", %{})} />
      <% end %>
    </div>
    """
  end

  defp flow_container_id(flow_id), do: "flow_container-#{flow_id}"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_flow_id(nil)
     |> assign_flow_payload(nil)}
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

  @impl Phoenix.LiveView
  def handle_event("kratos_flow:loaded", %{} = flow, socket) do
    {:noreply, assign_flow_payload(socket, flow)}
  end

  def assign_flow_id(socket, flow_id) do
    assign(socket, flow_id: flow_id)
  end

  def assign_flow_payload(socket, flow_payload) do
    assign(socket, flow_payload: flow_payload)
  end
end
