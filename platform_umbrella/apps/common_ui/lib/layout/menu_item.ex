defmodule CommonUI.Layout.MenuItem do
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
        "p-3",
        "rounded-md",
        "flex",
        "flex-col",
        "items-center",
        "text-sm",
        "font-medium"
      ] ++ @class}
    >
      <#slot />
      <span class="mt-2">{@name}</span>
    </LivePatch>
    """
  end
end
