defmodule ControlServerWeb.BatteriesFormSubcomponents do
  @moduledoc false

  use ControlServerWeb, :html

  alias CommonCore.Defaults.Images
  alias Phoenix.HTML.FormField

  slot :inner_block

  def image(assigns) do
    ~H"""
    <div class="bg-gray-darkest dark:bg-black font-mono font-bold text-sm text-gray-lighter rounded-lg whitespace-nowrap overflow-auto px-3 py-2">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :field, FormField, required: true
  attr :image_id, :atom, required: true
  attr :label, :string, required: true

  def image_version(assigns) do
    ~H"""
    <.field>
      <:label>{@label}</:label>
      <.input
        type="select"
        field={@field}
        placeholder="Choose a custom version"
        options={Images.get_image(@image_id).tags}
      />
    </.field>
    """
  end

  attr :field, FormField, required: true
  attr :label, :string, required: true
  attr :options, :list, default: []
  attr :disabled, :boolean, default: false
  attr :rest, :global

  def defaultable_field(assigns) do
    assigns = assign(assigns, :form, assigns.field.form)

    ~H"""
    <.field>
      <:label>{@label}</:label>
      <.input
        field={@form[override_field(@field)]}
        placeholder={value(@field)}
        options={@options}
        disabled={@disabled}
        {@rest}
      />
    </.field>
    """
  end

  defp override_field(%FormField{field: field}), do: String.to_existing_atom("#{field}_override")
  defp value(%FormField{value: value}), do: value
end
