defmodule Storybook.Components.Markdown do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Markdown.markdown/1
  def container, do: {:div, [class: "w-full p-4"]}

  @content """
  # Markdown

  This is a markdown component.

  - **Bold**
  - _Italic_
  - ~~Strikethrough~~
  - [Link](https://www.batteriesincl.com)

  ## Code

  ```elixir
  defmodule Test do
    def test do
      IO.puts ~s'Hello, World!'
    end
  end
  ```

  `inline code` is also supported.

  ---

  ## H2

  ### H3
  
  #### H4
  
  ##### H5
  
  ###### H6
  """

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          content: @content
        }
      }
    ]
  end
end
