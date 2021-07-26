defmodule CommonUI.Button do
  @moduledoc """
  Hello
  """
  use Surface.Component

  alias CommonUI.Theme, as: T

  @doc "The content of the button"
  slot default
  @doc "Triggered on click"
  prop click, :event
  @doc "The base classes that all buttons normally contain"
  prop base_class, :css_class, default: "items-center inline-flex"
  @doc "additional classes that can be added to the default"
  prop class, :css_class, default: ""
  prop theme, :string, default: "default", values: ~w(default primary)

  @doc "Add arbitrary attrs like multiple phx-value-* fields"
  prop opts, :keyword, default: []

  @doc """
  The button type, defaults to "button", mainly used for instances like modal X to close style buttons
  where you don't want to set a type at all. Setting to nil makes button have no type.
  """
  prop type, :string, default: "button"

  def render(assigns) do
    ~F"""
    <button
      type={@type}
      :on-click={@click}
      class={[T.value(:button, @theme), @base_class, @class]}
      {...@opts}
    >
      <#slot />
    </button>
    """
  end
end
