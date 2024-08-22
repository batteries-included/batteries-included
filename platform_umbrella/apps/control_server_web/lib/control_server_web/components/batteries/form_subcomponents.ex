defmodule ControlServerWeb.BatteriesFormSubcomponents do
  @moduledoc false

  use ControlServerWeb, :html

  alias Phoenix.HTML.Form

  attr :form, Form, required: true

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

  attr :form, Form, required: true

  def image(assigns) do
    ~H"""
    <div class="bg-gray-darkest font-mono font-bold text-sm text-gray-lighter rounded-lg whitespace-nowrap overflow-auto px-3 py-2">
      <%= @form[:image_override].value %>
    </div>
    """
  end
end
