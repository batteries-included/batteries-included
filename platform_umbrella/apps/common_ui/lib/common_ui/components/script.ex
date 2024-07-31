defmodule CommonUI.Components.Script do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon
  import CommonUI.Components.Tooltip

  alias CommonUI.IDHelpers

  attr :id, :string
  attr :class, :any, default: nil
  attr :src, :string, required: true
  attr :template, :string, default: "/bin/bash -c \"$(curl -fsSL @src)\""
  attr :rest, :global

  def script(assigns) do
    assigns = IDHelpers.provide_id(assigns)

    ~H"""
    <div
      class={[
        "relative flex items-center rounded-lg overflow-hidden h-14",
        "bg-gray-darkest-tint text-white text-lg tracking-tighter font-mono font-bold",
        @class
      ]}
      {@rest}
    >
      <div class="relative flex-1 h-full">
        <div id={@id} class="flex items-center absolute inset-0 whitespace-nowrap overflow-auto px-5">
          <%= String.replace(@template, "@src", @src) %>
        </div>
      </div>

      <.link id={"#{@id}-clipboard"} class={link_class()} phx-hook="Clipboard" data-to={"##{@id}"}>
        <.icon id={"#{@id}-clipboard-icon"} name={:square_2_stack} class="size-6" solid />
        <.icon id={"#{@id}-clipboard-check"} name={:check} class="size-6 text-green-400 hidden" solid />
      </.link>

      <.tooltip target_id={"#{@id}-clipboard"}>Copy to clipboard</.tooltip>

      <.link id={"#{@id}-open"} class={link_class()} href={@src} target="_blank">
        <.icon name={:arrow_top_right_on_square} class="size-6" solid />
      </.link>

      <.tooltip target_id={"#{@id}-open"}>Open script source</.tooltip>
    </div>
    """
  end

  defp link_class do
    "flex items-center justify-center size-14 bg-gray-darkest-tint border-l border-l-gray-darker-tint hover:bg-gray-darker-tint"
  end
end
