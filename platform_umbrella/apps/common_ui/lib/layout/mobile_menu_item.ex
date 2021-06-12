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
        "text-white",
        "group",
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
      <span class="ml-3 mt-2">{@name}</span>
    </LivePatch>
    """
  end
end
