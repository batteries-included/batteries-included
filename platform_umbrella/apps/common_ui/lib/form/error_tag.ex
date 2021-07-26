defmodule CommonUI.Form.ErrorTag do
  use Surface.Component
  @doc "Class or classes to apply to the input"
  prop class, :css_class, default: "mt-2 text-sm text-pink-800"

  def render(assigns) do
    ~F"""
    <Surface.Components.Form.ErrorTag {=@class} />
    """
  end
end
