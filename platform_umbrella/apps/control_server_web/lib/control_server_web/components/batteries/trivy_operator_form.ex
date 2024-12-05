defmodule ControlServerWeb.Batteries.TrivyOperatorForm do
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
          <.field>
            <:label>Version Tag</:label>
            <.input field={@form[:version_tag]} />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image>
            {@form[:image].value}<br />
            {@form[:node_collector_image].value}<br />
            {@form[:trivy_checks_image].value}
          </.image>

          <.image_version
            field={@form[:image_tag_override]}
            image_id={:trivy_operator}
            label="Version"
          />

          <.image_version
            field={@form[:node_collector_image_tag_override]}
            image_id={:aqua_node_collector}
            label="Node Collector Version"
          />

          <.image_version
            field={@form[:trivy_checks_image_tag_override]}
            image_id={:aqua_trivy_checks}
            label="Checks Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
