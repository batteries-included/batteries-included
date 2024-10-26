defmodule ControlServerWeb.Batteries.NotebooksForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        <%= @battery.description %>
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.field>
            <:label>Cookie Secret</:label>
            <.input type="password" field={@form[:cookie_secret]} disabled={@action != :new} />
          </.field>
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
