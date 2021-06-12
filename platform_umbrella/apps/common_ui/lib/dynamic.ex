defmodule CommonUI.Dynamic do
  use Surface.Component

  prop(component, :module, required: true)
  prop(props, :map, default: %{})

  def render(assigns) do
    props =
      assigns
      |> Map.get(:props)
      # Don't worry about this for now :)
      |> Map.merge(%{__surface__: %{groups: %{__default__: %{binding: false, size: 0}}}})

    ~F"""
    {live_component(@socket, @component, props)}
    """
  end
end
