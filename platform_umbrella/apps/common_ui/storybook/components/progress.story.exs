defmodule Storybook.Components.Progress do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Progress.progress/1
  def container, do: {:div, class: "w-full"}

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          current: 5,
          total: 10
        }
      },
      %Variation{
        id: :stepped,
        attributes: %{
          variant: "stepped",
          current: 2,
          total: 5
        }
      }
    ]
  end
end
