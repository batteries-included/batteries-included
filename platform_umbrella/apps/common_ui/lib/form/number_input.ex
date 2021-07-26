defmodule CommonUI.Form.NumberInput do
  use Surface.Component

  @doc "Class or classes to apply to the input"
  prop class, :css_class,
    default:
      "block w-full text-lg border-gray-300 rounded-md shadow-sm focus:ring-pink-500 focus:border-pink-500"

  def render(assigns) do
    ~F"""
    <Surface.Components.Form.NumberInput {=@class} />
    """
  end
end
