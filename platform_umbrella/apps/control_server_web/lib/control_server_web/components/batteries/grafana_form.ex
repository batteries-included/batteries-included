defmodule ControlServerWeb.Batteries.GrafanaForm do
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
            <:label>Admin Password</:label>
            <.input type="password" field={@form[:admin_password]} disabled={@action != :new} />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Images">
        <.fieldset>
          <.image>
            {@form[:image].value}<br />
            {@form[:sidecar_image].value}
          </.image>

          <.image_version
            field={@form[:image_tag_override]}
            image_id={:grafana}
            label="Grafana Version"
          />

          <.image_version
            field={@form[:sidecar_image_tag_override]}
            image_id={:kiwigrid_sidecar}
            label="Sidecar Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
