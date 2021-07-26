defmodule CommonUI.Progress.Step do
  use Surface.Component

  slot(default)
  prop(index, :integer, required: true)
  prop(name, :string, required: true)
  prop(is_done, :boolean, default: false)

  prop(change, :event, required: false)

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

  def render(assigns) do
    ~F"""
    <li class="md:flex-1">
      <!-- Completed Step -->
      <a
        href="#"
        class={border_classes(@is_done)}
        :on-click="progress:change"
        phx-value-payload={@index}
      >
        <span class={text_classes(@is_done)}>Step {@index + 1}</span>
        <span class="text-sm font-medium">{@name}</span>
      </a>
    </li>
    """
  end
end
