defmodule Storybook.Components.Video do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Video.video/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          src: "https://www.youtube.com/embed/dQw4w9WgXcQ?si=UZCUB2JKWZe3_5Uw",
          allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share",
          referrerpolicy: "strict-origin-when-cross-origin",
          allowfullscreen: true
        }
      }
    ]
  end
end
