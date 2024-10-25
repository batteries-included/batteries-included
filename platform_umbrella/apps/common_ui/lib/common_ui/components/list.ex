defmodule CommonUI.Components.List do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon

  attr :variant, :string, values: ["todo", "check"]
  attr :class, :any, default: nil
  attr :rest, :global

  slot :item do
    attr :class, :any
    attr :completed, :boolean
  end

  def list(%{variant: "todo"} = assigns) do
    ~H"""
    <ul class={["border-l-2 border-l-gray-lighter", @class]} {@rest}>
      <li
        :for={item <- @item}
        class={[
          "flex items-center gap-2 py-2 before:content-[''] before:inline-block before:w-5 before:h-0.5 before:bg-gray-lighter",
          item[:class]
        ]}
      >
        <.link
          class={[
            "inline-flex justify-start items-center gap-2 font-semibold hover:underline",
            item[:completed] && "line-through"
          ]}
          {assigns_to_attributes(item, [:class, :completed])}
        >
          <div class={[
            "flex items-center justify-center size-5 rounded-full",
            !item[:completed] && "border-2 border-gray-darker",
            item[:completed] && "bg-gray-darker text-white"
          ]}>
            <.icon :if={item[:completed]} name={:check} class="size-4" solid />
          </div>

          <%= render_slot(item) %>
        </.link>
      </li>
    </ul>
    """
  end

  def list(%{variant: "check"} = assigns) do
    ~H"""
    <ul
      class={["font-medium text-lg tracking-tight text-gray-darker-tint opacity-95", @class]}
      {@rest}
    >
      <li :for={item <- @item} class="flex items-center gap-3 mb-8 last:mb-0">
        <.icon name={:check_circle} class="size-7 text-green-500" />
        <%= render_slot(item) %>
      </li>
    </ul>
    """
  end
end
