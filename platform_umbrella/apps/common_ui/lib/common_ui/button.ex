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
    <button type={@type} class={["btn", "btn-outline", "btn-secondary", "glass", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
