defmodule ControlServerWeb.Projects.MachineLearningForm do
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
        title="Machine Learning"
        description="A place for information about the machine learning stage of project creation"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:size]}
          type="select"
          label="Size of the juypter notebook"
          placeholder="Choose size"
          options={[]}
        />

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
          field={@form[:db]}
          type="select"
          label="Existing set of databases"
          placeholder="Choose a set of databases"
          options={[]}
        />

        <.input
          :if={@db_type == :new}
          field={@form[:db]}
          type="select"
          label="Size of the database"
          placeholder="Choose size"
          options={[]}
        />

        <.input field={@form[:custom_fs]} type="switch" label="Use my own filesystem" />

        <.input
          :if={@form[:custom_fs].value}
          field={@form[:filesystem]}
          type="select"
          label="Choose values"
          placeholder="Choose values"
          options={[]}
        />

        <:actions>
          <%= render_slot(@inner_block) %>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
