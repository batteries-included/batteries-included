defmodule CommonUI.ShadowContainer do
  use Surface.Component

  slot default

  @impl true
  def render(assigns) do
    ~F"""
    <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
      <div class="overflow-hidden border-b border-gray-200 shadow sm:rounded-lg">
        <#slot />
      </div>
    </div>
    """
  end
end
