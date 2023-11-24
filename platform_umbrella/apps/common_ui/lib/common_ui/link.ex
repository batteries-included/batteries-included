defmodule CommonUI.Link do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.Component, except: [link: 1]

  attr :navigate, :any,
    doc: """
    Navigates from a LiveView to a new LiveView.
    The browser page is kept, but a new LiveView process is mounted and its content on the page
    is reloaded. It is only possible to navigate between LiveViews declared under the same router
    `Phoenix.LiveView.Router.live_session/3`. Otherwise, a full browser redirect is used.
    """

  attr :patch, :string,
    doc: """
    Patches the current LiveView.
    The `handle_params` callback of the current LiveView will be invoked and the minimum content
    will be sent over the wire, as any other LiveView diff.
    """

  attr :href, :any

  attr :variant, :string, default: "unstyled", values: ["styled", "external", "unstyled"]
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(download hreflang replace referrerpolicy rel target type)

  slot :inner_block, required: true
  def a(assigns)

  def a(%{variant: "external"} = assigns) do
    ~H"""
    <Phoenix.Component.link
      class={[link_class(@variant), @class]}
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

  def a(%{href: _} = assigns) do
    ~H"""
    <Phoenix.Component.link href={@href} class={[link_class(@variant), @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  def a(%{navigate: _} = assigns) do
    ~H"""
    <Phoenix.Component.link navigate={@navigate} class={[link_class(@variant), @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  def a(%{patch: _} = assigns) do
    ~H"""
    <Phoenix.Component.link patch={@patch} class={[link_class(@variant), @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  def a(assigns) do
    ~H"""
    <Phoenix.Component.link class={[link_class(@variant), @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </Phoenix.Component.link>
    """
  end

  defp link_class("styled" = _variant), do: "font-medium text-pink-500 hover:text-pink-600 hover:underline"

  defp link_class("external" = _variant), do: "font-medium text-pink-600 hover:underline flex"
  defp link_class(_variant), do: ""
end
