defmodule ControlServerWeb.Batteries.ForgejoForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description" class="lg:col-span-2">
        {@battery.description}
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.defaultable_field
            label="Admin Username"
            field={@form[:admin_username]}
            disabled={@action != :new}
          />

          <.field>
            <:label>Admin Password</:label>
            <.input type="password" field={@form[:admin_password]} disabled={@action != :new} />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image>{@form[:image].value}</.image>
          <.image_version field={@form[:image_tag_override]} image_id={:forgejo} label="Version" />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
