defmodule ControlServerWeb.Batteries.TraditionalServicesForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        <%= @battery.description %>
      </.panel>

      <.panel title="Configuration">
        <.simple_form variant="nested">
          <.input field={@form[:namespace]} label="Namespace" />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
