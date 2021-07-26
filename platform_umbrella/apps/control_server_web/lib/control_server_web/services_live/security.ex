defmodule ControlServerWeb.ServicesLive.Security do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use Surface.LiveView
  use Timex

  alias CommonUI.Button
  alias ControlServer.Services
  alias ControlServer.Services.Pods
  alias ControlServerWeb.Layout

  require Logger

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

    {:ok,
     socket
     |> assign(:pods, get_pods())
     |> assign(:running, Services.Security.active?())}
  end

  defp get_pods do
    :security |> Pods.get() |> Enum.map(&Pods.summarize/1)
  end

  @impl true
  @spec handle_info(:update, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, @pod_update_time)
    {:noreply, assign(socket, :pods, get_pods())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  @impl true
  def handle_event("start_service", _, socket) do
    {:ok, _service} = Services.Security.activate!()

    {:noreply, assign(socket, :running, true)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout>
      <div class="container">
        <h2 class="mt-2 text-2xl font-bold leading-7 text-pink-500 sm:text-3xl sm:truncate">
          Security
        </h2>
        <hr class="mt-4">
        {#if @running}
          <div class="mt-4 row">
            <div class="col">
              <ControlServerWeb.PodDisplay {=@pods} />
            </div>
          </div>
        {#else}
          <div class="mt-4 row">
            <div class="col align-self-center">
              The security service is not currently enabled on this Batteries included
              cluster. To start installing please press the button.
            </div>
          </div>
          <div class="row">
            <div class="m-5 text-center col align-self-center">
              <Button click="start_service">
                Install
              </Button>
            </div>
          </div>
        {/if}
      </div>
    </Layout>
    """
  end
end
