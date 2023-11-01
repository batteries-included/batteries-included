defmodule CommonUI.TabBar do
  @moduledoc false
  use CommonUI.Component

  defp link_class_base,
    do: "group relative min-w-0 flex-1 overflow-hidden py-3 px-4 text-sm font-medium text-center focus:z-10 rounded-lg"

  defp link_class(false),
    do: link_class_base() <> " text-gray-700 hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-gray-300"

  defp link_class(true), do: link_class_base() <> " text-white rounded-l-lg bg-primary-500"

  defp decoration_class(false), do: "bg-transparent absolute inset-x-0 bottom-0 h-0.5"
  defp decoration_class(true), do: "bg-pink-500 absolute inset-x-0 bottom-0 h-0.5"

  attr :tabs, :any, default: nil

  def tab_bar(assigns) do
    ~H"""
    <div class="block pb-8">
      <nav
        class={[
          "flex isolate rounded-lg border-gray-200 dark:bg-gray-800 dark:border-gray-600 border",
          "flex-col mx-5",
          "lg:flex-row lg:mx-0"
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
