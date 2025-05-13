defmodule ControlServerWeb.Batteries.CloudnativePGForm do
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
          <.image>{@form[:image].value}</.image>

          <.image_version
            field={@form[:image_tag_override]}
            image_id={:cloudnative_pg}
            label="Version"
          />
          <.image>{@form[:default_postgres_image].value}</.image>

          <.image_version
            field={@form[:default_postgres_image_tag_override]}
            image_id={:postgresql}
            label="Default Postgres Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
