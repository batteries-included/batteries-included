defmodule ControlServerWeb.Projects.WebForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  def mount(socket) do
    {:ok,
     socket
     |> assign(:class, nil)
     |> assign(:db_type, :existing)
     |> assign(:form, to_form(%{}))}
  end

  def handle_event("db_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :db_type, String.to_existing_atom(type))}
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
        title="Web"
        description="A place for information about the web stage of project creation"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:project_type]} type="radio">
          <:option value="internal">Internal web project</:option>
          <:option value="external">External web project</:option>
        </.input>

        <.tab_bar variant="secondary">
          <:tab
            phx-click="db_type"
            phx-value-type={:existing}
            phx-target={@myself}
            selected={@db_type == :existing}
          >
            Existing Database
          </:tab>

          <:tab
            phx-click="db_type"
            phx-value-type={:new}
            phx-target={@myself}
            selected={@db_type == :new}
          >
            New Database
          </:tab>
        </.tab_bar>

        <.input
          :if={@db_type == :existing}
          field={@form[:existing_db]}
          type="select"
          label="Existing set of databases"
          placeholder="Choose a set of databases"
          options={[]}
        />

        <.input
          :if={@db_type == :new}
          field={@form[:new_db]}
          type="select"
          label="Size of the database"
          placeholder="Choose size"
          options={[]}
        />

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
