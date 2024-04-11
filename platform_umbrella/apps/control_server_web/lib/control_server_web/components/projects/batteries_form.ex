defmodule ControlServerWeb.Projects.BatteriesForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  def mount(socket) do
    {:ok,
     socket
     |> assign(:class, nil)
     |> assign(:tab, :required)
     |> assign(:form, to_form(%{}))}
  end

  def handle_event("tab", %{"id" => id}, socket) do
    {:noreply, assign(socket, :tab, String.to_existing_atom(id))}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", params, socket) do
    # Don't create the resources yet, send data to parent liveview
    send(self(), {:next, {__MODULE__, params}})

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.simple_form
        id={@id}
        for={@form}
        class={@class}
        variant="stepped"
        title="Turn On Batteries You Need"
        description="A place for information about the batteries stage of project creation"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:search]} icon={:magnifying_glass} placeholder="Type to search..." />

        <.tab_bar variant="secondary">
          <:tab
            phx-click="tab"
            phx-value-id={:required}
            phx-target={@myself}
            selected={@tab == :required}
          >
            Required
          </:tab>

          <:tab phx-click="tab" phx-value-id={:db} phx-target={@myself} selected={@tab == :db}>
            Database Provider
          </:tab>

          <:tab phx-click="tab" phx-value-id={:web} phx-target={@myself} selected={@tab == :web}>
            Production Web
          </:tab>

          <:tab phx-click="tab" phx-value-id={:ml} phx-target={@myself} selected={@tab == :ml}>
            Machine Learning
          </:tab>

          <:tab phx-click="tab" phx-value-id={:all} phx-target={@myself} selected={@tab == :all}>
            All Batteries
          </:tab>
        </.tab_bar>

        <div :if={@tab == :required}>
          <.battery_toggle title="Redis" field={@form[:redis]}>
            In-memory data structure store, used as a database, cache, message broker and streaming engine.
          </.battery_toggle>

          <.battery_toggle title="PostgreSQL" field={@form[:postgres]}>
            Free and open-source relational database management system (RDBMS) that is known for its robustness, scalability, and extensibility
          </.battery_toggle>

          <.battery_toggle title="Rook" field={@form[:rook]}>
            Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
          </.battery_toggle>
        </div>

        <div :if={@tab == :db}>Database Provider</div>
        <div :if={@tab == :web}>Production Web</div>
        <div :if={@tab == :ml}>Machine Learning</div>
        <div :if={@tab == :all}>All Batteries</div>

        <:actions>
          <%= render_slot(@inner_block) %>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :rest, :global, include: ~w(field)

  slot :inner_block

  defp battery_toggle(assigns) do
    ~H"""
    <div class="flex items-start justify-between gap-x-12 mb-8 last:mb-0 pb-8 last:pb-0 border-b border-b-gray-lighter last:border-b-0">
      <div>
        <h3 class="text-xl font-semibold mb-2"><%= @title %></h3>
        <p class="text-sm"><%= render_slot(@inner_block) %></p>
      </div>

      <.input type="switch" {@rest} />
    </div>
    """
  end
end
