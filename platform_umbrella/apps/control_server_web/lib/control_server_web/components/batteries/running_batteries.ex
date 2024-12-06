defmodule ControlServerWeb.RunningBatteriesPanel do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias Phoenix.Naming

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, :class, nil)}
  end

  @impl Phoenix.LiveComponent
  def update(%{batteries: batteries} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:batteries, batteries)
     |> assign_batteries(:all)}
  end

  def assign_batteries(socket, tab) do
    filtered_batteries = Enum.filter(socket.assigns.batteries, fn b -> tab == :all || b.group == tab end)

    socket
    |> assign(:tab, tab)
    |> assign(:filtered_batteries, filtered_batteries)
  end

  @impl Phoenix.LiveComponent
  def handle_event("tab_select", %{"tab" => tab}, socket) do
    {:noreply, assign_batteries(socket, String.to_existing_atom(tab))}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class={@class}>
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
              selected={@tab == :ai}
              phx-click="tab_select"
              phx-value-tab="ai"
              phx-target={@myself}
            >
              AI
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

        <.table
          id="running-batteries-table"
          variant="paginated"
          rows={@filtered_batteries || []}
          meta={@meta}
          path={~p"/"}
        >
          <:col :let={battery} field={:type} label="Battery name">
            {Naming.humanize(battery.type)}
          </:col>
          <:col :let={battery} field={:group} label="Type">
            {battery.group}
          </:col>
          <:col :let={battery} field={:inserted_at} label="Installed">
            <.relative_display time={battery.inserted_at} />
          </:col>
          <:col :let={battery} field={:updated_at} label="Last Updated">
            <.relative_display time={battery.updated_at} />
          </:col>
        </.table>
      </.panel>
    </div>
    """
  end
end
