defmodule CommonUI.TabBar do
  @moduledoc false
  use CommonUI.Component

  defp link_class(false),
    do:
      "text-gray-500 hover:text-gray-700 group relative min-w-0 flex-1 overflow-hidden bg-white py-4 px-4 text-sm font-medium text-center hover:bg-gray-100 focus:z-10"

  defp link_class(true),
    do:
      "text-gray-900 rounded-l-lg group relative min-w-0 flex-1 overflow-hidden bg-white py-4 px-4 text-sm font-medium text-center hover:bg-gray-100 focus:z-10"

  defp decoration_class(false), do: "bg-transparent absolute inset-x-0 bottom-0 h-0.5"
  defp decoration_class(true), do: "bg-pink-500 absolute inset-x-0 bottom-0 h-0.5"

  attr :tabs, :any, default: nil

  def tab_bar(assigns) do
    ~H"""
    <div class="block pb-8">
      <nav
        class={[
          "flex isolate rounded-lg shadow divide-gray-200",
          "flex-col mx-5",
          "lg:flex-row lg:divide-x lg:mx-0"
        ]}
        aria-label="Tabs"
      >
        <.a :for={{tab_name, path, selected} <- @tabs} navigate={path} class={link_class(selected)}>
          <span><%= tab_name %></span>
          <span aria-hidden="true" class={decoration_class(selected)}></span>
        </.a>
      </nav>
    </div>
    """
  end
end
