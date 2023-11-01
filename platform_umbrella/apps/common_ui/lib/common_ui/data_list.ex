defmodule CommonUI.DataList do
  @moduledoc false
  use CommonUI.Component

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
    <dl class="-my-4 divide-y divide-gray-100">
      <div :for={item <- @item} class="flex gap-4 py-4 sm:gap-8">
        <dt class="flex-1 w-1/4 font-mono text-xl leading-6">
          <%= item.title %>
        </dt>
        <dd class="text-base leading-6 text-gray-700"><%= render_slot(item) %></dd>
      </div>
    </dl>
    """
  end

  @doc """
  Renders a data list as a set of pills.

  ## Examples

      <.data_pills>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.data_pills>
  """
  attr :rest, :global, doc: "attrs to put on the parent element"

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def data_pills(assigns) do
    ~H"""
    <dl class="flex gap-4" {@rest}>
      <div
        :for={item <- @item}
        class="flex gap-2 px-6 py-4 border border_gray-400 dark:border-gray-600 rounded-xl"
      >
        <dd class="text-2xl font-medium tracking-tight text-gray-700 dark:text-white">
          <%= render_slot(item) %>
        </dd>
        <dt class="flex-1 flex-shrink-0 dark:text-gray-400 tracking-tight w-1/4 mt-[2px]">
          <%= item.title %>
        </dt>
      </div>
    </dl>
    """
  end

  @doc """
  Renders a horizontal data list inside a long bordered pill.

  ## Examples

      <.data_horizontal_bordered>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.data_horizontal_bordered>
  """

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def data_horizontal_bordered(assigns) do
    ~H"""
    <div class="py-2 bg-white border border-gray-300 rounded-lg dark:bg-gray-800 dark:border-gray-700">
      <div class="flex text-sm font-light divide-x divide-gray-300 dark:divide-gray-700">
        <div :for={item <- @item} class="px-4">
          <span class="tracking-tighter text-gray-500 dark:text-gray-400"><%= item.title %>:</span>
          <span class="tracking-tighter text-black dark:text-white">
            <%= render_slot(item) %>
          </span>
        </div>
      </div>
    </div>
    """
  end

  attr :data, :list, doc: "data to display. A list of tuples: [{key, value}, {key, value}]"
  attr :class, :string, default: ""
  slot :inner_block

  def data_horizontal_plain(assigns) do
    ~H"""
    <div>
      <div
        :for={{key, value} <- @data}
        class={[
          "text-sm mx-4 px-1 font-light uppercase inline-flex text-gray-950 dark:text-white",
          @class
        ]}
      >
        <%= "#{key}=#{value}" %>
      </div>
    </div>
    """
  end
end
