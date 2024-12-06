defmodule ControlServerWeb.Batteries.KubeMonitoringForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description" class="lg:col-span-2">
        {@battery.description}
      </.panel>

      <.panel title="Images">
        <.fieldset>
          <.image>
            {@form[:kube_state_metrics_image].value}<br />
            {@form[:node_exporter_image].value}<br />
            {@form[:metrics_server_image].value}<br />
            {@form[:addon_resizer_image].value}
          </.image>

          <.image_version
            field={@form[:kube_state_metrics_tag_override]}
            image_id={:kube_state_metrics}
            label="Kube State Metrics Version"
          />

          <.image_version
            field={@form[:node_exporter_tag_override]}
            image_id={:node_exporter}
            label="Node Exporter Version"
          />

          <.image_version
            field={@form[:metrics_server_image_tag_override]}
            image_id={:metrics_server}
            label="Metrics Server Version"
          />

          <.image_version
            field={@form[:addon_resizer_image_tag_override]}
            image_id={:addon_resizer}
            label="Addon Resizer Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
