defmodule ControlServerWeb.Batteries.LokiForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Configuration">
        <.simple_form variant="nested">
          <.input field={@form[:replication_factor]} type="number" label="Replication Factor" />
          <.input field={@form[:replicas]} type="number" label="Replicas" />
        </.simple_form>
      </.panel>

      <.panel title="Image">
        <.simple_form variant="nested">
          <.image><%= @form[:image].value %></.image>
          <.image_version field={@form[:image_tag_override]} image_id={:loki} label="Version" />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
