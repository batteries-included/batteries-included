defmodule CommonUI.Components.TodoList do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon

  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block

  def todo_list(assigns) do
    ~H"""
    <ul class={["border-l-2 border-l-gray-lighter", @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </ul>
    """
  end

  attr :completed, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(navigate href)

  slot :inner_block

  def todo_list_item(assigns) do
    ~H"""
    <li class={[
      "flex items-center gap-2 py-2 before:content-[''] before:inline-block before:w-5 before:h-0.5 before:bg-gray-lighter",
      @class
    ]}>
      <.link
        class={[
          "inline-flex justify-start items-center gap-2 font-semibold hover:underline",
          @completed && "line-through"
        ]}
        {@rest}
      >
        <div class={[
          "flex items-center justify-center size-5 rounded-full",
          !@completed && "border-2 border-gray-darker",
          @completed && "bg-gray-darker text-white"
        ]}>
          <.icon :if={@completed} name={:check} class="size-4" solid />
        </div>

        <%= render_slot(@inner_block) %>
      </.link>
    </li>
    """
  end
end
