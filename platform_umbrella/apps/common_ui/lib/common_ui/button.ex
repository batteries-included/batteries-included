defmodule CommonUI.Button do
  @moduledoc false
  use CommonUI.Component

  @doc """
  Renders a button.
  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :value, :string, default: nil
  attr :name, :string, default: nil
  attr :class, :any, default: nil
  attr :variant, :string, default: "default", values: ["default", "filled", "unstyled"]
  attr :rest, :global, doc: "the arbitraty HTML attributes to apply to the button tag"

  slot :inner_block, required: true

  def button(%{variant: "default"} = assigns) do
    ~H"""
    <button
      class={
        build_class([
          "relative inline-flex items-center justify-center",
          "p-0.5 mb-2 mr-2 rounded-lg overflow-hidden",
          "text-sm font-medium text-gray-900",
          "transition-all ease-in-out duration-300 hover:scale-110",
          "bg-gradient-to-tl from-astral-500 to-pink-500",
          "group/button",
          "focus:ring-4 focus:outline-none focus:ring-pink-300",
          "hover:bg-gradient-to-bl hover:from-pink-500 hover:to-astral-500 hover:text-white hover:shadow-lg hover:shadow-pink-500/20 ",
          @class
        ])
      }
      name={@name}
      value={@value}
      type={@type}
      {@rest}
    >
      <span class={[
        "relative px-5 py-2.5 w-full rounded-md",
        "transition-all ease-in-out duration-300",
        "bg-white group-hover/button:bg-opacity-0"
      ]}>
        <%= render_slot(@inner_block) %>
      </span>
    </button>
    """
  end

  def button(%{variant: "unstyled"} = assigns) do
    ~H"""
    <button class={@class} type={@type} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def button(%{variant: "filled"} = assigns) do
    ~H"""
    <button
      class={
        build_class([
          "text-white text-center",
          "bg-gradient-to-br from-astral-600 to-pink-500 hover:bg-gradient-to-bl",
          "focus:ring-4 focus:outline-none focus:ring-pink-300 dark:focus:ring-pink-800",
          "font-medium rounded-lg text-md px-5 py-2.5",
          @class
        ])
      }
      type={@type}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
