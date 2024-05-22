defmodule Storybook.Components.Markdown do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Markdown.markdown/1

  defp big_content do
    """
    # Markdown

    This is a markdown component.

    - It supports lists
    - And with good spacing
    - And headers

    ## Subheader

    Subheaders are also supported `inline: code`.

    ```elixir
    defmodule Test do
      def test do
        IO.puts ~s'Hello, World!'
      end
    end
    ```
    """
  end

  def variations,
    do: [
      %Variation{id: :default, description: "Markdown Showcase", attributes: %{name: "showcase", content: big_content()}}
    ]
end
