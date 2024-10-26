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
        <.fieldset>
          <.field>
            <:label>Namespace</:label>
            <.input field={@form[:namespace]} />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image><%= @form[:pilot_image].value %></.image>

          <.image_version
            field={@form[:pilot_image_tag_override]}
            image_id={:istio_pilot}
            label="Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
