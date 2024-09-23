defmodule ControlServerWeb.Batteries.GrafanaForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        <%= @battery.description %>
      </.panel>

      <.panel title="Configuration">
        <.simple_form variant="nested">
          <.input
            field={@form[:admin_password]}
            type="password"
            label="Admin Password"
            disabled={@action != :new}
          />
        </.simple_form>
      </.panel>

      <.panel title="Images">
        <.simple_form variant="nested">
          <.image>
            <%= @form[:image].value %><br />
            <%= @form[:sidecar_image].value %>
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
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
