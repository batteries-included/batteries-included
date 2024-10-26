defmodule ControlServerWeb.Batteries.PromtailForm do
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
        <.fieldset>
          <.image><%= @form[:image].value %></.image>
          <.image_version field={@form[:image_tag_override]} image_id={:promtail} label="Version" />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
