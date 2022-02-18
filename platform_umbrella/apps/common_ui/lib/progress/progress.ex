defmodule CommonUI.Progress do
  use Phoenix.Component

  @base_border ~W(flex flex-col py-2 pl-4 border-l-4 md:pl-0 md:pt-4 md:pb-0 md:border-l-0 md:border-t-4)
  @done_border ~W(border-pink-600 group hover:border-pink-800)
  @todo_border ~W( border-gray-200 group hover:border-gray-300)

  @base_text ~W(text-xs font-semibold tracking-wide uppercase)
  @done_text ~W(text-pink-600  group-hover:text-pink-800)
  @todo_text ~W(text-gray-500  group-hover:text-gray-800)

  def border_classes(true), do: @base_border ++ @done_border
  def border_classes(false), do: @base_border ++ @todo_border

  def text_classes(true), do: @base_text ++ @done_text
  def text_classes(false), do: @base_text ++ @todo_text

  def step(assigns) do
    assigns =
      assigns
      |> assign_new(:is_done, fn -> false end)
      |> assign_new(:index, fn -> 0 end)

    ~H"""
    <li class="md:flex-1">
      <!-- Completed Step -->
      <a
        href="#"
        class={border_classes(@is_done)}
        :on-click="progress:change"
        phx-value-payload={@index}
      >
        <span class={text_classes(@is_done)}>
          Step&nbsp;<%= @index + 1 %>
        </span>
        <span class="text-sm font-medium">
          <%= @name %>
        </span>
      </a>
    </li>
    """
  end

  def progress_holder(assigns) do
    ~H"""
    <nav aria-label="Progress">
      <ol class="space-y-4 md:flex md:space-y-0 md:space-x-8">
        <%= render_slot(@inner_block) %>
      </ol>
    </nav>
    """
  end
end
