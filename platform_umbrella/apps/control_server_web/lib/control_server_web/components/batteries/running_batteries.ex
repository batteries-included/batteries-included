defmodule ControlServerWeb.RunningBatteriesPanel do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias ControlServer.Batteries
  alias Phoenix.Naming

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign_batteries(socket, :all)}
  end

  def assign_batteries(socket, tab) do
    batteries = Enum.filter(Batteries.list_system_batteries_slim(), fn b -> tab == :all || b.group == tab end)

    socket
    |> assign(:batteries, batteries)
    |> assign(:tab, tab)
  end

  @impl Phoenix.LiveComponent
  def handle_event("tab_select", %{"tab" => tab}, socket) do
    {:noreply, assign_batteries(socket, String.to_existing_atom(tab))}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="lg:col-span-12">
      <.panel title="Batteries Running" variant="gray">
        <:menu>
          <.tab_bar variant="borderless" class="w-full lg:basis-1/2">
            <:tab
              selected={@tab == :all}
              phx-click="tab_select"
              phx-value-tab="all"
              phx-target={@myself}
            >
              All
            </:tab>
            <:tab
              selected={@tab == :data}
              phx-click="tab_select"
              phx-value-tab="data"
              phx-target={@myself}
            >
              Data
            </:tab>
            <:tab
              selected={@tab == :devtools}
              phx-click="tab_select"
              phx-value-tab="devtools"
              phx-target={@myself}
            >
              Devtools
            </:tab>
            <:tab
              selected={@tab == :net_sec}
              phx-click="tab_select"
              phx-value-tab="net_sec"
              phx-target={@myself}
            >
              Net/Sec
            </:tab>
            <:tab
              selected={@tab == :ml}
              phx-click="tab_select"
              phx-value-tab="ml"
              phx-target={@myself}
            >
              ML
            </:tab>
            <:tab
              selected={@tab == :magic}
              phx-click="tab_select"
              phx-value-tab="magic"
              phx-target={@myself}
            >
              Magic
            </:tab>
          </.tab_bar>
        </:menu>

        <.table rows={@batteries || []}>
          <:col :let={battery} label="Battery name">
            <%= Naming.humanize(battery.type) %>
          </:col>
          <:col :let={battery} label="Type">
            <%= battery.group %>
          </:col>
          <:col :let={battery} label="Installed">
            <.relative_display time={battery.inserted_at} />
          </:col>
          <:col :let={battery} label="Last Updated">
            <.relative_display time={battery.updated_at} />
          </:col>
        </.table>
      </.panel>
    </div>
    """
  end
end
