defmodule CommonUI.Button do
  @moduledoc false
  use CommonUI.Component

  import CommonUI.Icon
  import CommonUI.Tooltip

  attr :variant, :string, values: ["primary", "secondary", "dark", "circle", "icon"]
  attr :class, :string, default: nil
  attr :icon, :atom, default: nil
  attr :icon_position, :atom, default: :left, values: [:left, :right]
  attr :rest, :global

  slot :inner_block

  def button(%{variant: "default"} = assigns) do
    assigns |> Map.put(:variant, "secondary") |> button()
  end

  def button(%{variant: "primary"} = assigns) do
    ~H"""
    <button
      class={[
        "min-w-36 rounded-lg text-white bg-primary enabled:hover:bg-primary-dark disabled:bg-gray-lighter",
        button_class(),
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon && @icon_position == :left} name={@icon} class={icon_class()} />
      <%= render_slot(@inner_block) %>
      <.icon :if={@icon && @icon_position == :right} name={@icon} class={icon_class()} />
    </button>
    """
  end

  def button(%{variant: "secondary"} = assigns) do
    ~H"""
    <button
      class={[
        "min-w-36 rounded-lg border border-gray-lighter text-gray-darker bg-white",
        "enabled:hover:text-primary enabled:hover:border-primary-light disabled:text-gray",
        button_class(),
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon && @icon_position == :left} name={@icon} class={icon_class()} />
      <%= render_slot(@inner_block) %>
      <.icon :if={@icon && @icon_position == :right} name={@icon} class={icon_class()} />
    </button>
    """
  end

  def button(%{variant: "dark"} = assigns) do
    ~H"""
    <button
      class={[
        "min-w-36 rounded-lg text-white bg-gray-darkest enabled:hover:bg-gray-darker disabled:bg-gray-lighter",
        button_class(),
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon && @icon_position == :left} name={@icon} class={icon_class()} />
      <%= render_slot(@inner_block) %>
      <.icon :if={@icon && @icon_position == :right} name={@icon} class={icon_class()} />
    </button>
    """
  end

  def button(%{variant: "circle"} = assigns) do
    ~H"""
    <button
      class={[
        "p-3 rounded-full border border-gray-lighter text-gray-darker",
        "enabled:hover:text-primary enabled:hover:border-primary-light disabled:text-gray",
        "disabled:cursor-not-allowed phx-submit-loading:opacity-75",
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} class={icon_class()} />
    </button>
    """
  end

  def button(%{variant: "icon"} = assigns) do
    ~H"""
    <button
      class={[
        "p-3 rounded-full text-gray-darker",
        "enabled:hover:text-primary enabled:hover:bg-gray-lightest/75 disabled:text-gray",
        "disabled:cursor-not-allowed phx-submit-loading:opacity-75",
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} class={icon_class()} />
    </button>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      class={[
        "text-gray-darker enabled:hover:text-primary disabled:text-gray-light",
        button_class(),
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon && @icon_position == :left} name={@icon} class={icon_class()} />
      <%= render_slot(@inner_block) %>
      <.icon :if={@icon && @icon_position == :right} name={@icon} class={icon_class()} />
    </button>
    """
  end

  defp icon_class, do: "size-5 text-current stroke-2"

  defp button_class,
    do: [
      "inline-flex items-center justify-center gap-2 px-5 py-3 font-semibold text-sm text-nowrap",
      "disabled:cursor-not-allowed phx-submit-loading:opacity-75"
    ]

  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :tooltip, :string, default: nil
  attr :icon, :atom
  attr :link_type, :string, default: "live_redirect"
  attr :rest, :global, include: ~w(to link_type)

  def action_icon(assigns) do
    ~H"""
    <PC.a id={@id} class={["cursor-pointer", @class]} link_type={@link_type} {@rest} size="xs">
      <.icon name={@icon} class="w-5 h-5 text-gray-darker dark:text-gray hover:text-primary-600" />

      <.tooltip :if={@tooltip} target_id={@id}>
        <%= @tooltip %>
      </.tooltip>
    </PC.a>
    """
  end
end
