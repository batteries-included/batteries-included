defmodule ControlServerWeb.Live.GroupBatteries do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  import CommonUI.Modal

  alias CommonCore.Batteries.Catalog

  alias ControlServer.Batteries
  alias ControlServer.Batteries.Installer

  alias EventCenter.Database, as: DatabaseEventCenter

  alias KubeServices.SnapshotApply.Apply

  alias Phoenix.Naming

  @impl Phoenix.LiveView
  def mount(%{"group" => group_str} = _params, _session, socket) do
    :ok = DatabaseEventCenter.subscribe(:system_battery)
    group = String.to_existing_atom(group_str)

    {:ok,
     socket
     |> assign_install_step(-1)
     |> assign_apply_result(nil)
     |> assign_install_result(nil)
     |> assign_group(group)
     |> assign_title(group)
     |> assign_installing_battery_type(nil)}
  end

  @doc """
  If there's a battery_type in the url then we are currently installing. We
  should only ever patch this in. So no need for mount.
  """
  @impl Phoenix.LiveView
  def handle_params(
        %{"group" => group_str, "battery_type" => installing_type_str} = _params,
        _url,
        socket
      ) do
    group = String.to_existing_atom(group_str)
    installing_type = String.to_existing_atom(installing_type_str)

    {:noreply,
     socket
     |> assign_group(group)
     |> assign_title(group)
     |> assign_catalog_batteries(group)
     |> assign_system_batteries(group)
     |> assign_installing_battery_type(installing_type)}
  end

  def handle_params(%{"group" => group_str} = _params, _url, socket) do
    group = String.to_existing_atom(group_str)

    {:noreply,
     socket
     |> assign_group(group)
     |> assign_title(group)
     |> assign_catalog_batteries(group)
     |> assign_system_batteries(group)}
  end

  defp assign_catalog_batteries(socket, group) do
    assign(socket, :catalog_batteries, Catalog.all(group))
  end

  def assign_group(socket, group) do
    assign(socket, group: group)
  end

  defp assign_installing_battery_type(socket, type) do
    assign(socket, :installing_battery_type, type)
  end

  defp assign_title(socket, group) when is_atom(group) do
    assign(socket, :page_title, group_title(group))
  end

  defp assign_system_batteries(socket, group) do
    map =
      group
      |> Batteries.list_system_batteries_for_group()
      |> Enum.map(&{&1.type, &1})
      |> Map.new()

    assign(socket, :system_batteries, map)
  end

  def assign_install_step(socket, step) do
    assign(socket, :install_step, step)
  end

  def assign_install_result(socket, install_result) do
    assign(socket, install_result: install_result)
  end

  def assign_apply_result(socket, apply_result) do
    assign(socket, apply_result: apply_result)
  end

  @doc """
  The event handler for live view
  """
  def handle_event(_msg, _params, _socket)

  @impl Phoenix.LiveView
  def handle_event("start", %{"type" => type} = _params, socket) do
    progress_target = self()

    _ =
      Task.async(fn ->
        # Yes these are sleeps to make this slower.
        #
        # There's a lot going on here an showing the user
        # that is somewhat important. Giving some time inbetween
        # these steps show that there's stuff happening to them.
        Process.sleep(500)
        _res = Installer.install!(type, progress_target)
        Process.sleep(500)
        {:ok, apply_result} = Apply.run()
        send(progress_target, {:async_installer, {:apply_complete, apply_result}})
        Process.sleep(500)
        {:async_installer, :full_complete}
      end)

    {:noreply,
     socket
     |> assign_install_step(-1)
     |> assign_install_result(nil)
     |> assign_apply_result(nil)
     |> push_patch(to: ~p"/batteries/#{socket.assigns.group}/install/#{type}")}
  end

  @impl Phoenix.LiveView
  def handle_info({:async_installer, {:apply_complete, apply_result}}, socket) do
    # This is the handler for making progress from the async install task
    {:noreply,
     socket
     |> assign_install_step(socket.assigns.install_step + 1)
     |> assign_apply_result(apply_result)}
  end

  @impl Phoenix.LiveView
  def handle_info({:async_installer, {:install_complete, install_result}}, socket) do
    # This is the handler for making progress from the async install task
    {:noreply,
     socket
     |> assign_install_step(socket.assigns.install_step + 1)
     |> assign_install_result(install_result)}
  end

  @impl Phoenix.LiveView
  def handle_info({:async_installer, _msg}, socket) do
    # This is the handler for making progress from the async install task
    {:noreply, assign_install_step(socket, socket.assigns.install_step + 1)}
  end

  @impl Phoenix.LiveView
  def handle_info({_ref, {:async_installer, _msg}}, socket) do
    # This is the last message sent from the install task.
    {:noreply, assign_install_step(socket, 1000)}
  end

  @impl Phoenix.LiveView
  # This is the async task finishing and tearing down.
  def handle_info({:DOWN, _, :process, _, :normal}, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(_msg, socket) do
    {:noreply, assign_system_batteries(socket, socket.assigns.group)}
  end

  defp group_title(:ml) do
    "Machine Learning Batteries"
  end

  defp group_title(:net_sec) do
    "Network/Security Batteries"
  end

  defp group_title(group) do
    string_title =
      group
      |> Atom.to_string()
      |> String.capitalize()

    "#{string_title} Batteries"
  end

  defp active_check(assigns) do
    ~H"""
    <div class="flex text-shamrock-700 font-semi-bold">
      <div class="flex-initial">
        Active
      </div>
      <div class="flex-none ml-2">
        <Heroicons.check_circle class="h-6 w-6" />
      </div>
    </div>
    """
  end

  attr :battery, :any, required: true

  def start_button(assigns) do
    ~H"""
    <.button phx-click={:start} phx-value-type={@battery.type}>
      Install Battery
    </.button>
    """
  end

  def install_summary(assigns) do
    ~H"""
    <.h3 class="text-astral-800 text-right">Summary</.h3>
    <.data_list>
      <:item title="Installed Battery Count">
        <%= map_size(@install_result.installed) %>
      </:item>
      <:item title="Previously Installed dependencies">
        <%= map_size(@install_result.selected) %>
      </:item>
      <:item :if={@apply_result != nil} title="Kubernetes Deploy">
        <%= @apply_result.status %>
      </:item>
      <:item :if={@apply_result != nil} title="Deploy Status Page">
        <.link navigate={~p"/snapshot_apply/#{@apply_result.id}/show"} variant="styled">
          Show Deploy
        </.link>
      </:item>
    </.data_list>
    """
  end

  def install_modal(assigns) do
    ~H"""
    <.modal
      show={true}
      id="install-progress"
      on_cancel={JS.navigate(~p"/batteries/#{@group}", replace: true)}
    >
      <:title>
        <.h2 variant="fancy">Installing Batteries</.h2>
      </:title>
      <div class="flex flex-row mt-5 space-x-4">
        <.vertical_steps current_step={@current_step}>
          <:step>Generate Configuration</:step>
          <:step>Install Batteries</:step>
          <:step>Write to Database</:step>
          <:step>Deploy to Kubernetes</:step>
        </.vertical_steps>
        <div>
          <.install_summary
            :if={@install_result != nil}
            install_result={@install_result}
            apply_result={@apply_result}
          />
        </div>
      </div>
    </.modal>
    """
  end

  defp is_active(active, type), do: Map.has_key?(active, type)

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.layout group={@group} active={:batteries}>
      <:title>
        <.title><%= @page_title %></.title>
      </:title>
      <.install_modal
        :if={@live_action == :install}
        current_step={@install_step}
        group={@group}
        install_result={@install_result}
        apply_result={@apply_result}
      />
      <.table id="batteries-table" rows={@catalog_batteries}>
        <:col :let={battery} label="Type">
          <%= Naming.humanize(battery.type) %>
        </:col>
        <:col :let={battery} label="Group">
          <%= battery.group %>
        </:col>
        <:col :let={battery} label="Status">
          <.active_check :if={is_active(@system_batteries, battery.type)} />
        </:col>
        <:action :let={battery}>
          <.start_button :if={!is_active(@system_batteries, battery.type)} battery={battery} />
        </:action>
      </.table>
    </.layout>
    """
  end
end
