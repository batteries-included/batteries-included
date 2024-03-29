defmodule ControlServerWeb.Projects.DatabaseForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  def mount(socket) do
    {:ok,
     socket
     |> assign(:class, nil)
     |> assign(:form, to_form(%{"postgres" => true}))}
  end

  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, :form, to_form(params))}
  end

  def handle_event("save", params, socket) do
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
        title="Database Only"
        description="A place for information about the database stage of project creation"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:postgres]} type="switch" label="I need a postgres instance" />

        <.grid :if={@form[:postgres].value} variant="col-2">
          <.input
            field={@form[:postgres_size]}
            type="select"
            label="Size"
            placeholder="Choose value"
            options={[]}
          />

          <.input
            field={@form[:postgres_storage_size]}
            type="select"
            label="Storage Size"
            placeholder="Choose value"
            options={[]}
          />

          <.input
            field={@form[:postgres_memory]}
            type="select"
            label="Memory"
            placeholder="Choose value"
            options={[]}
          />

          <.input
            field={@form[:postgres_memory]}
            type="select"
            label="CPU Limits"
            placeholder="Choose value"
            options={[]}
          />
        </.grid>

        <.input field={@form[:redis]} type="switch" label="I need a redis instance" />

        <.grid :if={@form[:redis].value} variant="col-2">
          <.input
            field={@form[:redis_size]}
            type="select"
            label="Size"
            placeholder="Choose value"
            options={[]}
          />

          <.input
            field={@form[:redis_storage_size]}
            type="select"
            label="Storage Size"
            placeholder="Choose value"
            options={[]}
          />

          <.input
            field={@form[:redis_memory]}
            type="select"
            label="Memory"
            placeholder="Choose value"
            options={[]}
          />

          <.input
            field={@form[:redis_memory]}
            type="select"
            label="CPU Limits"
            placeholder="Choose value"
            options={[]}
          />
        </.grid>

        <:actions>
          <%= render_slot(@inner_block) %>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
