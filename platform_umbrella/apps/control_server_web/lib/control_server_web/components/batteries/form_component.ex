defmodule ControlServerWeb.BatteriesFormComponent do
  @moduledoc false

  use ControlServerWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, :form, to_form(%{}))}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:title, assigns.battery.name <> " Battery")}
  end

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.form id={@id} for={@form} phx-change="validate" phx-submit="save">
        <.page_header title={@title} back_link={~p"/batteries/#{@battery.group}"}>
          <:menu :if={@action == :edit}>
            <.badge minimal label="ACTIVE" class="bg-green-500 text-white" />
          </:menu>

          <div class="flex items-center gap-8">
            <.button :if={@action == :edit} variant="minimal" icon={:power}>
              Uninstall
            </.button>

            <.button variant="dark" type="submit">
              <%= if @action == :new, do: "Install", else: "Save" %> Battery
            </.button>
          </div>
        </.page_header>

        <.grid columns={%{sm: 1, lg: 2}}>
          <.panel title="Description">
            <%= @battery.description %>
          </.panel>

          <.panel title="Configuration">
            <p class="text-gray-light">No custom configuration is available for this battery.</p>
          </.panel>
        </.grid>
      </.form>
    </div>
    """
  end
end
