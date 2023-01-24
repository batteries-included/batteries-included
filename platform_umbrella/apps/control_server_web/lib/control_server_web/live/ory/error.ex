defmodule ControlServerWeb.Live.OryKratosError do
  use ControlServerWeb, :live_view

  import KubeServices.SystemState.SummaryHosts
  import ControlServerWeb.Loader

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.loader :if={@error_payload == nil} />
    <div :if={@id != nil} id="kratos-errors" phx-hook="Kratos" data-url={@url}>
      Error
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id} = _params, _uri, socket) do
    {:noreply, socket |> assign_id(id) |> assign_url(errors_url(id))}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_id(nil) |> assign_error_payload(nil)}
  end

  @impl Phoenix.LiveView
  def handle_event("kratos:loaded", %{} = payload, socket) do
    {:noreply, assign_error_payload(socket, payload)}
  end

  def assign_id(socket, id) do
    assign(socket, id: id)
  end

  def assign_url(socket, url) do
    assign(socket, url: url)
  end

  def assign_error_payload(socket, payload) do
    assign(socket, error_payload: payload)
  end

  def errors_url(id), do: "http://#{kratos_host()}/self-service/errors?id=#{id}"
end
