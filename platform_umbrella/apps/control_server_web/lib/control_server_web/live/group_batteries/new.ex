defmodule ControlServerWeb.GroupBatteries.NewLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Batteries.Catalog
  alias ControlServer.Batteries.Installer
  alias ControlServerWeb.BatteriesFormComponent

  def mount(%{"battery_type" => battery_type} = params, _session, socket) do
    battery = Catalog.get(battery_type)
    redirect_to = Map.get(params, "redirect_to", ~p"/batteries/#{battery.group}")

    {:ok,
     socket
     |> assign(:current_page, battery.group)
     |> assign(:page_title, "#{battery.name} Battery")
     |> assign(:redirect_to, redirect_to)
     |> assign(:battery, battery)
     |> assign(:installing, false)
     |> assign(:completed, false)
     |> assign(:install_result, nil)
     |> assign(:apply_result, nil)
     # Each progress update happens after that event is completed,
     # so keep the current step index one step behind so it shows
     # the correct step text.
     |> assign(:current_step, -1)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    target = self()

    _ =
      Task.async(fn ->
        # Yes these are sleeps to make this slower.
        #
        # There's a lot going on here an showing the user
        # that is somewhat important. Giving some time inbetween
        # these steps show that there's stuff happening to them.
        Process.sleep(800)
        Installer.install!(socket.assigns.battery.type, target)
        Process.sleep(800)
        send(target, {:async_installer, :starting_kube})
        KubeServices.SnapshotApply.Worker.start()
        Process.sleep(800)
        send(target, {:async_installer, {:apply_complete, "Started"}})
      end)

    {:noreply, assign(socket, :installing, true)}
  end

  def handle_info({:async_installer, {:install_complete, install_result}}, socket) do
    {:noreply,
     socket
     |> assign(:current_step, socket.assigns.current_step + 1)
     |> assign(:install_result, install_result)}
  end

  def handle_info({:async_installer, {:install_failed, _failed_result}}, socket) do
    {:noreply, socket}
  end

  def handle_info({:async_installer, {:apply_complete, apply_result}}, socket) do
    {:noreply,
     socket
     |> assign(:current_step, socket.assigns.current_step + 1)
     |> assign(:apply_result, apply_result)}
  end

  def handle_info({:async_installer, _}, socket) do
    {:noreply, assign(socket, :current_step, socket.assigns.current_step + 1)}
  end

  def handle_info({:DOWN, _, :process, _, _}, socket) do
    {:noreply, assign(socket, :completed, true)}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={BatteriesFormComponent}
      id="new-batteries-form"
      action={:new}
      battery={@battery}
    />

    <.modal :if={@installing} id="install-modal" allow_close={false} show>
      <:title>Installing <%= @battery.name %></:title>

      <.progress total={install_steps() |> Enum.count()} current={max(@current_step, 0)} />

      <div :if={step = install_steps() |> Enum.at(@current_step)} class="mt-2 text-sm text-gray-light">
        <%= step %>
      </div>

      <.data_list :if={@completed && @install_result != nil} class="mt-4 bg-gray-lightest p-6">
        <:item title="New Batteries Installed">
          <%= map_size(@install_result.installed) %>
        </:item>

        <:item title="Batteries Already Installed">
          <%= map_size(@install_result.selected) %>
        </:item>

        <:item :if={@apply_result != nil} title="Kubernetes Deploy Status">
          <%= @apply_result %>
        </:item>
      </.data_list>

      <:actions :if={@completed}>
        <.button variant="secondary" link={@redirect_to} icon={:check_circle}>
          Done
        </.button>
      </:actions>
    </.modal>
    """
  end

  defp install_steps do
    [
      "Starting Installation",
      "Generating Configuration",
      "Installing Batteries",
      "Deploying to Kubernetes"
    ]
  end
end
