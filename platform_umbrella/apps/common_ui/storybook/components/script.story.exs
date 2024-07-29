defmodule Storybook.Components.Script do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Script.script/1
  def container, do: {:div, class: "p-10"}
  def layout, do: :one_column

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          src: "https://install.example.com/8ej3l"
        }
      },
      %Variation{
        id: :with_template,
        attributes: %{
          src: "https://install.example.com/8ej3l",
          template: "wget @src"
        }
      }
    ]
  end
end
