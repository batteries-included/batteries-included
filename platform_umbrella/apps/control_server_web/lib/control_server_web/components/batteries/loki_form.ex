defmodule ControlServerWeb.Batteries.LokiForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description" class="lg:col-span-2">
        {@battery.description}
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.field>
            <:label>Replication Factor</:label>
            <.input field={@form[:replication_factor]} type="number" />
          </.field>

          <.field>
            <:label>Replicas</:label>
            <.input field={@form[:replicas]} type="number" />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image>{@form[:image].value}</.image>
          <.image_version field={@form[:image_tag_override]} image_id={:loki} label="Version" />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
