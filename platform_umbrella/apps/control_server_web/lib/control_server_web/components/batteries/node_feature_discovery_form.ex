defmodule ControlServerWeb.Batteries.NodeFeatureDiscoveryForm do
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

          <.image_version
            field={@form[:image_tag_override]}
            image_id={:node_feature_discovery}
            label="Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
