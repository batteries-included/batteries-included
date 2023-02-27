defmodule CommonUI.DataList do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]

  @doc """
  Renders a data list.

  ## Examples

      <.data_list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.data_list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def data_list(assigns) do
    ~H"""
    <dl class="-my-4 divide-y divide-gray-100">
      <div :for={item <- @item} class="flex py-4 gap-4 sm:gap-8">
        <dt class="w-1/4 flex-1 text-xl leading-6 font-mono">
          <%= item.title %>
        </dt>
        <dd class="text-base leading-6 text-gray-700"><%= render_slot(item) %></dd>
      </div>
    </dl>
    """
  end
end
