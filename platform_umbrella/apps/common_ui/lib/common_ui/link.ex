defmodule CommonUI.Link do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  import CommonUI.CSSHelpers

  attr :navigate, :any, default: nil

  attr :href, :any

  attr :variant, :string, default: "unstyled"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(download hreflang referrerpolicy rel target type)

  slot :inner_block, required: true

  def link(%{variant: "styled"} = assigns) do
    ~H"""
    <Phoenix.Component.link
      class={
        build_class([
          "font-medium text-secondary-500 hover:text-secondary-600 hover:underline",
          @class
        ])
      }
      navigate={@navigate}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  def link(%{variant: "external"} = assigns) do
    ~H"""
    <Phoenix.Component.link
      class={build_class(["font-medium text-pink-600 hover:underline flex", @class])}
      href={@href || @navigate}
      target="_blank"
      {@rest}
    >
      <span class="flex-initial">
        <%= render_slot(@inner_block) %>
      </span>
      <Heroicons.arrow_top_right_on_square class="ml-2 w-5 h-5 flex-none" />
    </Phoenix.Component.link>
    """
  end

  def link(%{href: _} = assigns) do
    ~H"""
    <Phoenix.Component.link href={@href} class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  def link(%{variant: "unstyled", navigate: _} = assigns) do
    ~H"""
    <Phoenix.Component.link navigate={@navigate} class={build_class(@class)} {@rest}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  def link(assigns) do
    ~H"""
    <Phoenix.Component.link class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end
end
