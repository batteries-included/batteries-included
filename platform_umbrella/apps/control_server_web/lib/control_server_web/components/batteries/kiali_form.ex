defmodule ControlServerWeb.Batteries.KialiForm do
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
          <.input field={@form[:login_signing_key]} type="password" label="Login Signing Key" />
        </.fieldset>
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image><%= @form[:image].value %></.image>
          <.image_version field={@form[:image_tag_override]} image_id={:kiali} label="Version" />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
