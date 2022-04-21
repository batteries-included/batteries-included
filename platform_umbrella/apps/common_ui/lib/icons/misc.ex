defmodule CommonUI.Icons.Misc do
  use Phoenix.Component

  def check_mark(assigns) do
    assigns = assign_new(assigns, :class, fn -> "" end)

    ~H"""
    <svg
      version="1.1"
      xmlns="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      viewBox="0 0 512 512"
      style="enable-background:new 0 0 512 512;"
      xml:space="preserve"
      stroke="currentColor"
      fill="currentColor"
      class={"h-6 w-6 " <> @class}
    >
      <g>
        <g>
          <path d="M256,0C114.84,0,0,114.842,0,256s114.84,256,256,256s256-114.842,256-256S397.16,0,256,0z M256,462.452
    c-113.837,0-206.452-92.614-206.452-206.452S142.163,49.548,256,49.548S462.452,142.163,462.452,256S369.837,462.452,256,462.452z
    " />
        </g>
      </g>
      <g>
        <g>
          <polygon points="345.838,164.16 222.968,287.029 157.904,221.967 122.87,257.001 222.968,357.1 380.872,199.194 		" />
        </g>
      </g>
    </svg>
    """
  end
end
