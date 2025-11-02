defmodule ControlServerWeb.Batteries.VMAgentForm do
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
          <.field>
            <:label>Cookie Secret</:label>
            <.input type="password" field={@form[:cookie_secret]} disabled={@action != :new} />
          </.field>
          <.image_version
            field={@form[:image_tag_override]}
            image_id={:vm_agent}
            label="VM Agent Tag"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
