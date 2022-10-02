defmodule CommonUI.Link do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]

  attr :navigate, :any

  attr :href, :any

  attr :type, :string, default: "unstyled"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(download hreflang referrerpolicy rel target type)

  slot(:inner_block, required: true)

  def link(%{type: "styled"} = assigns) do
    ~H"""
    <Phoenix.Component.link
      class={["font-semibold link link-secondary hover:no-underline", @class]}
      navigate={@navigate}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  def link(%{type: "external"} = assigns) do
    ~H"""
    <Phoenix.Component.link
      class={["font-semibold link link-secondary flex", @class]}
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

  def link(%{type: "unstyled", navigate: _} = assigns) do
    ~H"""
    <Phoenix.Component.link navigate={@navigate} class={@class} {@rest}>
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
