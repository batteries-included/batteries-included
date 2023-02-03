defmodule CommonUI.Typogoraphy do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  import CommonUI.CSSHelpers

  attr(:class, :any, default: "")
  attr(:base_class, :string, default: "text-5xl leading-7 text-pink-500 sm:text-3xl sm:truncate")
  slot(:inner_block, required: true)
  attr(:rest, :global)

  def h1(assigns) do
    ~H"""
    <h1 class={build_class([@base_class, @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end

  attr(:class, :any, default: "")
  attr(:base_class, :string, default: "text-3xl sm:text-3xl font-bold leading-loose")
  attr(:color_class, :string, default: "text-astral-700")

  attr(:fancy_class, :string,
    default: "text-transparent bg-clip-text bg-gradient-to-br from-pink-500 to-astral-500 "
  )

  attr(:variant, :string, default: "default", values: ["default", "fancy"])
  slot(:inner_block, required: true)
  attr(:rest, :global)

  def h2(%{variant: "fancy"} = assigns) do
    ~H"""
    <h2 class={build_class([@base_class, @class])} {@rest}>
      <span class={build_class([@fancy_class])}>
        <%= render_slot(@inner_block) %>
      </span>
    </h2>
    """
  end

  def h2(%{variant: _} = assigns) do
    ~H"""
    <h2 class={build_class([@base_class, @color_class, @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </h2>
    """
  end

  attr(:class, :any, default: "")

  attr(:base_class, :string,
    default: "text-xl sm:text-2xl font-semibold leading-loose text-gray-600"
  )

  slot(:inner_block, required: true)
  attr(:rest, :global)

  def h3(assigns) do
    ~H"""
    <h3 class={build_class([@base_class, @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </h3>
    """
  end

  attr(:class, :any, default: "")

  attr(:base_class, :string, default: "text-lg font-bold leading-loose text-blizzard-blue-800")

  slot(:inner_block, required: true)
  attr(:rest, :global)

  def h4(assigns) do
    ~H"""
    <h4 class={build_class([@base_class, @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </h4>
    """
  end
end
