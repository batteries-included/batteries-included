defmodule CommonUI.Components.DataList do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Container
  import CommonUI.Components.Typography

  @doc """
  Renders a data list.

  ## Examples

      <.data_list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.data_list>
  """
  slot :item, required: true do
    attr(:title, :string, required: true)
  end

  def data_list(assigns) do
    ~H"""
    <.grid columns={12} class="text-darker dark:text-gray-lighter">
      <%= for item <- @item || [] do %>
        <div class="text-xl leading-4 col-span-5">
          <%= item.title %>
        </div>
        <div class="text-base leading-4 col-span-7">
          <%= render_slot(item) %>
        </div>
      <% end %>
    </.grid>
    """
  end

  attr :data, :list, doc: "data to display. A list of tuples: [{key, value}, {key, value}]"
  attr :class, :string, default: ""
  slot :inner_block

  def data_horizontal_plain(assigns) do
    ~H"""
    <div>
      <span
        :for={{key, value} <- @data}
        class={[
          "text-sm mr-4 font-light uppercase text-gray-950 dark:text-white",
          @class
        ]}
      >
        <%= "#{key}=#{value}" %>
      </span>
    </div>
    """
  end

  attr :data, :list, doc: "data to display. A list of tuples: [{key, value}, {key, value}]"
  attr :class, :string, default: ""
  attr :rest, :global

  def data_horizontal_bolded(assigns) do
    ~H"""
    <div {@rest} class={["flex justify-between", @class]}>
      <.flex :for={{key, value} <- @data} class="items-center justify-center">
        <span class="text-sm"><%= key %></span>

        <.h5 class="font-semibold">
          <%= value %>
        </.h5>
      </.flex>
    </div>
    """
  end
end
