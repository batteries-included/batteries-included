defmodule CommonUI.Icons.Training do
  use Surface.Component

  prop(class, :css_class, default: [])

  def render(assigns) do
    ~F"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={["h-6", "w-6"] ++ @class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-linecap="round"
      stroke-linejoin="round"
      stroke-width="2"
    >
      <path stroke="none" d="M0 0h24v24H0z" fill="none" />
      <path d="M21 13c0 -3.87 -3.37 -7 -10 -7h-8" />
      <path d="M3 15h16a2 2 0 0 0 2 -2" />
      <path d="M3 6v5h17.5" />
      <line x1="3" y1="10" x2="3" y2="14" />
      <line x1="8" y1="11" x2="8" y2="6" />
      <line x1="13" y1="11" x2="13" y2="6.5" />
      <line x1="3" y1="19" x2="21" y2="19" />
    </svg>
    """
  end
end
