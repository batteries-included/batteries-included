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
  attr :variant, :string, default: "default", values: ["default", "unstyled", "transparent"]
  attr :icon, :atom, default: nil
  attr :rest, :global, doc: "the arbitraty HTML attributes to apply to the button tag"

  slot :inner_block, required: true

  def button(%{variant: "default"} = assigns) do
    ~H"""
    <PC.button
      class={@class}
      name={@name}
      value={@value}
      type={@type}
      color="light"
      variant="shadow"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </PC.button>
    """
  end

  def button(%{variant: "unstyled"} = assigns) do
    ~H"""
    <button class={@class} type={@type} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def button(%{variant: "transparent"} = assigns) do
    ~H"""
    <button
      type={@type}
      {@rest}
      class={[
        "flex items-center gap-4 group text-primary-500 hover:text-primary-700 group-hover:fill-primary-700",
        @class
      ]}
    >
      <PC.icon :if={@icon} name={@icon} class={["w-4 h-4 fill-primary-500", icon_class(@icon)]} />
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp icon_class(:plus), do: "stroke-[3]"
  defp icon_class(_), do: nil

  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :tooltip, :string, default: nil
  attr :icon, :atom
  attr :link_type, :string, default: "live_redirect"
  attr :rest, :global, include: ~w(to link_type)

  def action_icon(assigns) do
    ~H"""
    <PC.a id={@id} class={["cursor-pointer", @class]} link_type={@link_type} {@rest} size="xs">
      <PC.icon
        name={@icon}
        solid
        class="w-5 h-5 text-gray-600 dark:text-gray-400 hover:text-primary-600"
      />
      <CommonUI.Tooltip.tooltip :if={@tooltip} target_id={@id}>
        <%= @tooltip %>
      </CommonUI.Tooltip.tooltip>
    </PC.a>
    """
  end
end
