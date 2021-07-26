defmodule CommonUI.Form.TextInput do
  use Surface.Component

  @doc "Class or classes to apply to the input"
  prop class, :css_class,
    default:
      "block w-full text-lg border-gray-300 rounded-md shadow-sm focus:ring-pink-500 focus:border-pink-500"

  @doc "Options list"
  prop opts, :keyword, default: []

  def render(assigns) do
    ~F"""
    <Surface.Components.Form.TextInput {=@class} {=@opts} />
    """
  end
end
