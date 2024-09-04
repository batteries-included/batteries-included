defmodule ControlServerWeb.Batteries.CloudnativePGForm do
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
        <.simple_form variant="nested">
          <.image><%= @form[:image].value %></.image>

          <.image_version
            field={@form[:image_tag_override]}
            image_id={:cloudnative_pg}
            label="Version"
          />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
