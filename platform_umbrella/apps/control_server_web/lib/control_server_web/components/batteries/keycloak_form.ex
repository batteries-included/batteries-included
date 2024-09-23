defmodule ControlServerWeb.Batteries.KeycloakForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        <%= @battery.description %>
      </.panel>

      <.panel title="Image">
        <.simple_form variant="nested">
          <.image><%= @form[:image].value %></.image>
          <.image_version field={@form[:image_tag_override]} image_id={:keycloak} label="Version" />
        </.simple_form>
      </.panel>

      <.panel title="Configuration">
        <.simple_form variant="nested">
          <.input field={@form[:admin_username]} label="Admin Username" disabled={@action != :new} />

          <.input
            disabled={@action != :new}
            field={@form[:admin_password]}
            type="password"
            label="Admin Password"
          />

          <.input field={@form[:log_level]} label="Log Level" />
          <.input field={@form[:replicas]} type="number" label="Replicas" />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
