defmodule ControlServerWeb.ActionsDropdown do
  @moduledoc false

  use ControlServerWeb, :html

  attr :rest, :global, include: ~w(id), doc: "Attributes for the dropdown component"

  slot :inner_block,
    required: true,
    doc: "The content of the dropdown, typically dropdown links or buttons"

  def actions_dropdown(assigns) do
    ~H"""
    <.dropdown {@rest}>
      <:trigger>
        <.button icon={:chevron_down} icon_position={:right} variant="secondary">
          <.icon name={:cog} class="mr-2 size-6 inline-block" /> Actions
        </.button>
      </:trigger>

      {render_slot(@inner_block)}
    </.dropdown>
    """
  end
end
