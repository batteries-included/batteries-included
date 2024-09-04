defmodule ControlServerWeb.Batteries.StaleResourceCleanerForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Configuration">
        <.simple_form variant="nested">
          <.input field={@form[:delay]} type="number" label="Delay" />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
