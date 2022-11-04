defmodule CommonUI.Button do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]

  @doc """
  Renders a button.
  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :variant, :string, default: "default"
  attr :rest, :global, doc: "the arbitraty HTML attributes to apply to the button tag"

  slot :inner_block, required: true

  def button(%{variant: "default"} = assigns) do
    ~H"""
    <button
      class={[
        "relative inline-flex items-center justify-center",
        "p-0.5 mb-2 mr-2 overflow-hidden text-sm font-medium",
        "text-gray-900 rounded-lg group",
        "bg-gradient-to-br from-primary-600 to-secondary-500",
        "group-hover:from-secondary-500 group-hover:to-primary-600 group-hover:text-white hover:text-white",
        "focus:ring-5 focus:outline-none focus:ring-blue-300",
        @class
      ]}
      type={@type}
      {@rest}
    >
      <span class={[
        "relative px-5 py-2.5 transition-all",
        "ease-in duration-200 bg-white rounded-md",
        "group-hover:bg-opacity-0"
      ]}>
        <%= render_slot(@inner_block) %>
      </span>
    </button>
    """
  end

  def button(%{variant: "filled"} = assigns) do
    ~H"""
    <button
      class={[
        "text-white text-center",
        "bg-gradient-to-br from-primary-600 to-secondary-500 hover:bg-gradient-to-bl",
        "focus:ring-3 focus:outline-none focus:ring-pink-300 dark:focus:ring-pink-800",
        "font-medium rounded-lg text-md px-5 py-2.5",
        @class
      ]}
      type={@type}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
