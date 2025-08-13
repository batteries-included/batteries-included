defmodule ControlServerWeb.Batteries.CloudnativePGBarmanForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        {@battery.description}
      </.panel>

      <.panel title="Images">
        <.fieldset>
          <.image>{@form[:barman_plugin_image].value}</.image>

          <.image_version
            field={@form[:barman_plugin_image_override]}
            image_id={:cnpg_plugin_barman}
            label="Plugin Version"
          />
          <.image>{@form[:barman_plugin_sidecar_image].value}</.image>

          <.image_version
            field={@form[:barman_plugin_sidecar_image_override]}
            image_id={:cnpg_plugin_barman_sidecar}
            label="Sidecar Image Version"
          />
        </.fieldset>
      </.panel>

      <.panel title="Object Store Settings">
        <.fieldset>
          <.input field={@form[:service_role_arn]} label="Service Role ARN" />
          <.input field={@form[:bucket_name]} label="Bucket Name" />
          <.input field={@form[:bucket_arn]} label="Bucket ARN" />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
