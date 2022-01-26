defmodule CommonUI.ShadowContainer do
  use Phoenix.Component

  def shadow_container(assigns) do
    ~H"""
    <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
      <div class="overflow-hidden border-b border-gray-200 shadow sm:rounded-lg">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
