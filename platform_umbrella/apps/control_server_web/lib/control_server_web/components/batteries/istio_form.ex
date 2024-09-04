defmodule ControlServerWeb.Batteries.IstioForm do
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
          <.input field={@form[:namespace]} label="Namespace" />
        </.simple_form>
      </.panel>

      <.panel title="Image">
        <.simple_form variant="nested">
          <.image><%= @form[:pilot_image].value %></.image>

          <.image_version
            field={@form[:pilot_image_tag_override]}
            image_id={:istio_pilot}
            label="Version"
          />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
