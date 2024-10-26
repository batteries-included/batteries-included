defmodule ControlServerWeb.Batteries.IstioGatewayForm do
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
          <.image><%= @form[:proxy_image].value %></.image>

          <.image_version
            field={@form[:proxy_image_tag_override]}
            image_id={:istio_proxy}
            label="Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
