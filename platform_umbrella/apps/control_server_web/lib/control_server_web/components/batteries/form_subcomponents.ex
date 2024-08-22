defmodule ControlServerWeb.BatteriesFormSubcomponents do
  @moduledoc false

  use ControlServerWeb, :html

  attr :form, Phoenix.HTML.Form, required: true

  def empty_config(assigns) do
    ~H"""
    <.input type="hidden" field={@form[:type]} />

    <div>
      <.panel title="Configuration">
        <p>This battery doesn't support custom configuration yet.</p>
      </.panel>
    </div>
    """
  end
end
