defmodule CommonUI.Components.Markdown do
  @moduledoc false

  use CommonUI, :component

  import Phoenix.HTML

  attr :class, :any, default: nil
  attr :base_class, :any, default: "prose lg:prose-xl"
  attr :tag, :string, default: "section"
  attr :content, :string
  attr :rest, :global

  def markdown(assigns) do
    value = generate_content(assigns.content)
    assigns = Map.put(assigns, :content, value)

    ~H"""
    <.dynamic_tag name={@tag} class={[@base_class, @class]} {@rest}>
      <%= raw(@content) %>
    </.dynamic_tag>
    """
  end

  defp generate_content(content) do
    Md.Parser.generate(content, parser: markdown_parser())
  end

  defp markdown_parser, do: CommonUI.Helpers.Parser
end
