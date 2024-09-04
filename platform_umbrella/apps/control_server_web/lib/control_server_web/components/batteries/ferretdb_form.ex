defmodule ControlServerWeb.Batteries.FerretDBForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.empty_config form={@form} />

      <.panel title="Image">
        <.simple_form variant="nested">
          <.image><%= @form[:ferretdb_image].value %></.image>

          <.image_version
            field={@form[:ferretdb_image_tag_override]}
            image_id={:ferretdb}
            label="Version"
          />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
