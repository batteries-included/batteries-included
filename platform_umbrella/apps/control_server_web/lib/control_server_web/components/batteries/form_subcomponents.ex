defmodule ControlServerWeb.BatteriesFormSubcomponents do
  @moduledoc false

  use ControlServerWeb, :html

  alias CommonCore.Defaults.Images

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

  slot :inner_block

  def image(assigns) do
    ~H"""
    <div class="bg-gray-darkest font-mono font-bold text-sm text-gray-lighter rounded-lg whitespace-nowrap overflow-auto px-3 py-2">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :image_id, :atom, required: true
  attr :label, :string, required: true

  def image_version(assigns) do
    ~H"""
    <.input
      field={@field}
      type="select"
      placeholder="Choose a custom version"
      label={@label}
      options={Images.get_image(@image_id).tags}
    />
    """
  end
end
