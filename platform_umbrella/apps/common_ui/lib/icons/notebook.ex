defmodule CommonUI.Icons.Notebook do
  use Phoenix.Component

  def render(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={"h-6 w-6" <> @class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      stroke-width="2"
    >
      <path stroke="none" d="M0 0h24v24H0z" fill="none" />
      <path d="M6 4h11a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-11a1 1 0 0 1 -1 -1v-14a1 1 0 0 1 1 -1m3 0v18" />
      <line x1="13" y1="8" x2="15" y2="8" />
      <line x1="13" y1="12" x2="15" y2="12" />
    </svg>
    """
  end
end
