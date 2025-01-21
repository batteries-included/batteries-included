defmodule CommonUI.Components.DataList do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Container
  import CommonUI.Components.Icon
  import CommonUI.Components.Tooltip
  import CommonUI.Components.Typography
  import CommonUI.IDHelpers

  attr :variant, :string, values: ["horizontal-plain", "horizontal-bolded"]
  attr :data, :list, doc: "data to display. A list of tuples: [{key, value}, {key, value}]"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block

  slot :item do
    attr :title, :string, required: true
    attr :help, :string
  end

  def data_list(%{variant: "horizontal-plain"} = assigns) do
    ~H"""
    <div>
      <span
        :for={{key, value} <- @data}
        class={[
          "text-sm mr-4 font-light uppercase text-gray-950 dark:text-white",
          @class
        ]}
      >
        {"#{key}=#{value}"}
      </span>
    </div>
    """
  end

  def data_list(%{variant: "horizontal-bolded"} = assigns) do
    ~H"""
    <div {@rest} class={["flex justify-between", @class]}>
      <.flex :for={{key, value} <- @data} class="items-center justify-center">
        <span class="text-sm">{key}</span>

        <.h5 class="font-semibold">
          {value}
        </.h5>
      </.flex>
    </div>
    """
  end

  def data_list(assigns) do
    assigns = provide_id(assigns)

    ~H"""
    <div
      class={[
        "grid grid-cols-[auto,1fr] items-start text-darker dark:text-gray-lighter gap-x-12 gap-y-4",
        @class
      ]}
      {@rest}
    >
      <%= for {item, idx} <- Enum.with_index(@item) do %>
        <div class="text-gray-light text-md font-medium leading-5">
          {item.title}
          <div :if={item[:help]} class="inline-block ml-1 align-middle">
            <.icon
              solid
              id={"#{@id}-#{idx}-help"}
              name={:question_mark_circle}
              class="size-5 opacity-30 hover:opacity-100"
            />

            <.tooltip target_id={"#{@id}-#{idx}-help"}>
              {item.help}
            </.tooltip>
          </div>
        </div>

        <div class="text-base leading-5">
          {render_slot(item)}
        </div>
      <% end %>
    </div>
    """
  end
end
