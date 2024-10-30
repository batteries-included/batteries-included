defmodule CommonUI.Components.Markdown do
  @moduledoc false

  use CommonUI, :component

  import Phoenix.HTML

  attr :tag, :string, default: "section"
  attr :class, :any, default: nil
  attr :content, :string
  attr :options, :list, default: []
  attr :rest, :global

  def markdown(assigns) do
    ~H"""
    <.dynamic_tag name={@tag} class={["prose dark:prose-invert", @class]} {@rest}>
      <%= render(@content, @options) %>
    </.dynamic_tag>
    """
  end

  defp render(content, opts) do
    default_opts = [
      code_class_prefix: "lang-",
      # Since we are using `Phoenix.HTML.html_escape/1`
      # and we don't want to escape entities twice
      escape: false
    ]

    content
    |> String.trim()
    |> html_escape()
    |> safe_to_string()
    |> Earmark.as_html!(opts ++ default_opts)
    |> raw()
  end
end
