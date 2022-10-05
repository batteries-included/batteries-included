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
  attr :rest, :global, doc: "the arbitraty HTML attributes to apply to the button tag"

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "btn",
        "border-none",
        "bg-gradient-to-r from-pink-400 via-pink-500 to-pink-600 outline-none",
        "hover:bg-gradient-to-br",
        "focus:ring-4 focus:outline-none focus:ring-pink-300",
        "text-white text-center",
        "px-7",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
