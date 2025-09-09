defmodule ControlServerWeb.Batteries.StaleResourceCleanerForm do
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
          <.defaultable_field label="Delay" type="number" field={@form[:delay]} />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
