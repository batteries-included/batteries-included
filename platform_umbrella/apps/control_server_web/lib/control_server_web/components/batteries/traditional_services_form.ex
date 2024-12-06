defmodule ControlServerWeb.Batteries.TraditionalServicesForm do
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
            <:label>Namespace</:label>
            <.input field={@form[:namespace]} />
          </.field>
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
