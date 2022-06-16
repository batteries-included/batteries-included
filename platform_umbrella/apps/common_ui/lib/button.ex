defmodule CommonUI.Button do
  use Phoenix.Component

  import Phoenix.LiveView.Helpers

  alias PetalComponents.Button

  def button(assigns) do
    assigns =
      assigns
      |> assign_new(:inner_block, fn -> nil end)
      |> assign_new(:label, fn -> "" end)
      |> assign_new(:color, fn -> :primary end)
      |> assign_new(:size, fn -> :responsive end)

    assigns =
      assigns
      |> assign(:class, button_classes(assigns))
      |> assign_new(:extra_assigns, fn ->
        assigns_to_attributes(assigns, ~w(label color size class inner_block)a)
      end)

    ~H"""
    <Button.button classes={@class} {@extra_assigns}>
      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% else %>
        <%= @label %>
      <% end %>
    </Button.button>
    """
  end

  def button_classes(assigns) do
    size_class = size_classes(assigns)
    color_class = color_classes(assigns)
    user_class = Map.get(assigns, :class, "")
    "btn #{size_class} #{color_class} #{user_class}"
  end

  def size_classes(%{size: size}) do
    case size do
      :responsive -> "btn-xs sm:btn-sm md:btn-md"
      :lg -> "btn-lg"
      :md -> "btn-md"
      :sm -> "btn-sm"
      :xs -> "btn-xs"
    end
  end

  @doc """
  Get the color for any known variant.
  These are explicitly enumerated to get css minification to no remove the class names.
  """
  def color_classes(%{color: color}) do
    case color do
      :primary -> "btn-primary"
      :secondary -> "btn-secondary"
      :accent -> "btn-accent"
      :warning -> "btn-warning"
      :error -> "btn-error"
      :link -> "btn-link"
      :ghost -> "btn-ghost"
    end
  end
end
