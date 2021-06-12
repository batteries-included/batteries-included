defmodule CommonUI.Progress do
  use Surface.Component

  slot(default)

  def render(assigns) do
    ~F"""
    <nav aria-label="Progress">
      <ol class="space-y-4 md:flex md:space-y-0 md:space-x-8">
        <#slot />
      </ol>
    </nav>
    """
  end
end
