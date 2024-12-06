defmodule ControlServerWeb.Batteries.RedisForm do
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
            {@form[:operator_image].value}<br />
            {@form[:redis_image].value}<br />
            {@form[:exporter_image].value}
          </.image>

          <.image_version
            field={@form[:operator_image_tag_override]}
            image_id={:redis_operator}
            label="Operator Version"
          />

          <.image_version
            field={@form[:redis_image_tag_override]}
            image_id={:redis}
            label="Redis Version"
          />

          <.image_version
            field={@form[:exporter_image_tag_override]}
            image_id={:redis_exporter}
            label="Exporter Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
