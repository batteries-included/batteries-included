defmodule ControlServerWeb.Batteries.StaleResourceCleanerForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        {@battery.description}
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.field>
            <:label>Delay</:label>
            <.input type="number" field={@form[:delay]} />
          </.field>
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
