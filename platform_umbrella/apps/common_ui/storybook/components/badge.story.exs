defmodule Storybook.Components.Badge do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Badge.badge/1

  def variations,
    do: [
      %Variation{id: :with_value, attributes: %{value: 5, label: "Foobar"}},
      %Variation{id: :with_items, slots: [~s|<:item label="Foo">Bar</:item>|, ~s|<:item label="Baz">Qux</:item>|]},
      %Variation{id: :minimal, attributes: %{minimal: true, label: "Foobar"}}
    ]
end
