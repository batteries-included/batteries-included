defmodule CommonUI.Layout.MobileMenuItem do
  use Surface.Component

  alias Surface.Components.LivePatch

  prop(class, :css_class, default: [])
  prop(name, :string, required: true)
  prop(to, :string, required: true)
  slot(default)

  def render(assigns) do
    ~F"""
    <LivePatch
      to={"#{@to}"}
      class={[
        "group",
        "w-full",
        "py-2",
        "px-3",
        "rounded-md",
        "flex",
        "items-center",
        "text-sm",
        "font-medium"
      ] ++ @class}
    >
      <#slot />
      <span class="mt-2 ml-3">{@name}</span>
    </LivePatch>
    """
  end
end
