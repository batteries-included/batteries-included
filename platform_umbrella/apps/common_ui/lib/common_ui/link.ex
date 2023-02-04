defmodule CommonUI.Link do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  import CommonUI.CSSHelpers

  attr(:navigate, :any,
    doc: """
    Navigates from a LiveView to a new LiveView.
    The browser page is kept, but a new LiveView process is mounted and its content on the page
    is reloaded. It is only possible to navigate between LiveViews declared under the same router
    `Phoenix.LiveView.Router.live_session/3`. Otherwise, a full browser redirect is used.
    """
  )

  attr(:patch, :string,
    doc: """
    Patches the current LiveView.
    The `handle_params` callback of the current LiveView will be invoked and the minimum content
    will be sent over the wire, as any other LiveView diff.
    """
  )

  attr :href, :any

  attr :variant, :string, default: "unstyled", values: ["styled", "external", "unstyled"]
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(download hreflang referrerpolicy rel target type)

  slot :inner_block, required: true
  def link(assigns)

  def link(%{variant: "external"} = assigns) do
    ~H"""
    <Phoenix.Component.link
      class={build_class([link_class(@variant), @class])}
      href={@href}
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
    <Phoenix.Component.link href={@href} class={build_class([link_class(@variant), @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  def link(%{navigate: _} = assigns) do
    ~H"""
    <Phoenix.Component.link
      navigate={@navigate}
      class={build_class([link_class(@variant), @class])}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  def link(%{patch: _} = assigns) do
    ~H"""
    <Phoenix.Component.link patch={@patch} class={build_class([link_class(@variant), @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  def link(assigns) do
    ~H"""
    <Phoenix.Component.link class={build_class([link_class(@variant), @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  defp link_class("styled" = _variant),
    do: "font-medium text-pink-500 hover:text-pink-600 hover:underline"

  defp link_class("external" = _variant), do: "font-medium text-pink-600 hover:underline flex"
  defp link_class(_variant), do: ""
end
