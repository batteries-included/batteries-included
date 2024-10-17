defmodule CommonUI.Components.Field do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon
  import CommonUI.Components.Tooltip
  import CommonUI.IDHelpers

  attr :id, :string
  attr :variant, :string, default: "stacked", values: ["stacked", "beside"]
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  slot :label do
    attr :help, :string
    attr :class, :any
  end

  slot :note do
    attr :class, :any
  end

  def field(assigns) do
    assigns = provide_id(assigns)

    ~H"""
    <label class={["w-full", @class]} {@rest}>
      <div class={[@variant == "beside" && "grid grid-cols-1 lg:grid-cols-2 gap-x-4 gap-y-2"]}>
        <div
          :for={label <- @label}
          class={[
            "flex items-center gap-2 text-sm text-gray-darkest dark:text-gray-lighter",
            @variant == "stacked" && "mb-2",
            label[:class]
          ]}
        >
          <div><%= render_slot(label) %></div>

          <div :if={label[:help]}>
            <.icon
              solid
              id={"#{@id}-help"}
              name={:question_mark_circle}
              class="size-5 opacity-30 hover:opacity-100"
            />

            <.tooltip target_id={"#{@id}-help"}>
              <%= label.help %>
            </.tooltip>
          </div>
        </div>

        <%= render_slot(@inner_block) %>
      </div>

      <div :for={note <- @note} class={["text-xs text-gray-light mt-2", note[:class]]}>
        <%= render_slot(note) %>
      </div>
    </label>
    """
  end
end
