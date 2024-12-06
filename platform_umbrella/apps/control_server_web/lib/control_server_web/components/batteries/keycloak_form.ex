defmodule ControlServerWeb.Batteries.KeycloakForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        {@battery.description}
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image>{@form[:image].value}</.image>
          <.image_version field={@form[:image_tag_override]} image_id={:keycloak} label="Version" />
        </.fieldset>
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.field>
            <:label>Admin Username</:label>
            <.input field={@form[:admin_username]} disabled={@action != :new} />
          </.field>

          <.field>
            <:label>Admin Password</:label>
            <.input type="password" field={@form[:admin_password]} disabled={@action != :new} />
          </.field>

          <.field>
            <:label>Log Level</:label>
            <.input field={@form[:log_level]} />
          </.field>

          <.field>
            <:label>Replicas</:label>
            <.input type="number" field={@form[:replicas]} />
          </.field>
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
