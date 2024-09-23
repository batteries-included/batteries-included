defmodule ControlServerWeb.Batteries.ForgejoForm do
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
        <.simple_form variant="nested">
          <.input field={@form[:admin_username]} label="Admin Username" disabled={@action != :new} />
          <.input
            field={@form[:admin_password]}
            type="password"
            label="Admin Password"
            disabled={@action != :new}
          />
        </.simple_form>
      </.panel>

      <.panel title="Image">
        <.simple_form variant="nested">
          <.image><%= @form[:image].value %></.image>
          <.image_version field={@form[:image_tag_override]} image_id={:forgejo} label="Version" />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
