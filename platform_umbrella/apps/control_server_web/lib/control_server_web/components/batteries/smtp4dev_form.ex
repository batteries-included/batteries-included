defmodule ControlServerWeb.Batteries.Smtp4devForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description" class="lg:col-span-2">
        <%= @battery.description %>
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.field>
            <:label>Cookie Secret</:label>
            <.input type="password" field={@form[:cookie_secret]} disabled={@action != :new} />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image><%= @form[:image].value %></.image>
          <.image_version field={@form[:image_tag_override]} image_id={:smtp4dev} label="Version" />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
