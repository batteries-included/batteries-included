defmodule ControlServerWeb.Batteries.MetalLBForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        {@battery.description}
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.field variant="beside">
            <:label>Enable Pod Monitor</:label>
            <.input type="switch" field={@form[:enable_pod_monitor]} />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Images">
        <.fieldset>
          <.image>
            {@form[:speaker_image].value}<br />
            {@form[:controller_image].value}<br />
            {@form[:frrouting_image].value}
          </.image>

          <.image_version
            field={@form[:speaker_image_tag_override]}
            image_id={:metallb_speaker}
            label="Speaker Version"
          />

          <.image_version
            field={@form[:controller_image_tag_override]}
            image_id={:metallb_controller}
            label="Controller Version"
          />

          <.image_version
            field={@form[:frrouting_image_tag_override]}
            image_id={:frrouting_frr}
            label="Routing Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
