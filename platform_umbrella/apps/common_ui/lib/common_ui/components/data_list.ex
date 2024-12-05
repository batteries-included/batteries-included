defmodule CommonUI.Components.DataList do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Container
  import CommonUI.Components.Typography

  attr :variant, :string, values: ["horizontal-plain", "horizontal-bolded"]
  attr :data, :list, doc: "data to display. A list of tuples: [{key, value}, {key, value}]"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block

  slot :item do
    attr :title, :string, required: true
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
    ~H"""
    <div
      class={[
        "grid grid-cols-[auto,1fr] items-start text-darker dark:text-gray-lighter gap-x-12 gap-y-4",
        @class
      ]}
      {@rest}
    >
      <%= for item <- @item do %>
        <div class="text-gray-light text-md font-medium leading-5">
          {item.title}
        </div>

        <div class="text-base leading-5">
          {render_slot(item)}
        </div>
      <% end %>
    </div>
    """
  end
end
