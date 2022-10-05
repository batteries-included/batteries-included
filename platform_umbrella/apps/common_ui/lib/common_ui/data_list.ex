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
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-fuscous-gray-100">
        <div :for={item <- @item} class="flex gap-4 py-4 sm:gap-8">
          <dt class="w-1/4 flex-none text-sm leading-6 text-fuscous-gray-500">
            <%= item.title %>
          </dt>
          <dd class="text-sm leading-6 text-fuscous-gray-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end
end
