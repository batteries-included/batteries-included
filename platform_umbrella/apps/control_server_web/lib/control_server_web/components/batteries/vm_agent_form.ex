defmodule ControlServerWeb.Batteries.VMAgentForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Configuration">
        <.simple_form variant="nested">
          <.input field={@form[:cookie_secret]} type="password" label="Cookie Secret" />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
