defmodule CommonUI.DataList do
  @moduledoc false
  use CommonUI.Component

  import CommonUI.Container
  import CommonUI.Typography

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
    <.grid columns={12}>
      <%= for item <- @item || [] do %>
        <div class="text-xl leading-6 col-span-5">
          <%= item.title %>
        </div>
        <div class="text-base leading-6 col-span-7">
          <%= render_slot(item) %>
        </div>
      <% end %>
    </.grid>
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
    <dl class="flex gap-4 lg:gap-6" {@rest}>
      <div
        :for={item <- @item}
        class="flex gap-2 px-6 py-4 border border-gray dark:border-gray-darker rounded-xl"
      >
        <dd class="text-2xl font-medium tracking-tight text-gray-darkest dark:text-white">
          <%= render_slot(item) %>
        </dd>
        <dt class="flex-1 flex-shrink-0 dark:text-gray tracking-tight w-1/4 mt-[2px]">
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
  attr :class, :string, default: ""

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def data_horizontal_bordered(assigns) do
    ~H"""
    <div class={[
      "py-2 bg-white border border-gray-light rounded-lg dark:bg-gray-darkest dark:border-gray-darkest",
      @class
    ]}>
      <.flex class="text-sm font-light divide-x divide-gray-light dark:divide-gray-darkest justify-between items-center">
        <.flex :for={item <- @item} class="px-3">
          <span class="tracking-tighter text-gray-dark dark:text-gray"><%= item.title %>:</span>
          <span class="tracking-tighter text-black dark:text-white">
            <%= render_slot(item) %>
          </span>
        </.flex>
      </.flex>
    </div>
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
        <PC.form_label class="!mb-0" label={key} />
        <.h5 class="font-semibold">
          <%= value %>
        </.h5>
      </.flex>
    </div>
    """
  end
end
