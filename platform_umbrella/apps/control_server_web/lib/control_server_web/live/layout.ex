defmodule ControlServerWeb.Live.Layout do
  use Surface.Component

  alias CommonUI.Layout.MenuItem
  alias CommonUI.Layout.MobileMenuItem

  slot(default, required: true)

  @hover_classes ["hover:bg-astral-500", "hover:text-pink-500"]

  def render(assigns) do
    hvc = @hover_classes

    ~F"""
    <CommonUI.Layout bg_class="bg-astral-400">
      <:main_menu>
        <MenuItem to="/services/database" name="Database" class={hvc}>
          <CommonUI.Icons.Database class={["text-white"]} />
        </MenuItem>
        <MenuItem to="/services/training" name="Training" class={hvc}>
          <CommonUI.Icons.Training class={["text-white"]} />
        </MenuItem>
        <MenuItem to="/services/notebooks" name="Training" class={hvc}>
          <CommonUI.Icons.Notebook class={["text-white"]} />
        </MenuItem>
        <MenuItem to="/services/monitoring" name="Monitoring" class={hvc}>
          <CommonUI.Icons.Monitoring class={["text-white"]} />
        </MenuItem>
        <MenuItem to="/services/devtools" name="Devtools" class={hvc}>
          <CommonUI.Icons.Devtools class={["text-white"]} />
        </MenuItem>
        <MenuItem to="/services/security" name="Security" class={hvc}>
          <CommonUI.Icons.Security class={["text-white"]} />
        </MenuItem>
      </:main_menu>

      <:mobile_menu>
        <MobileMenuItem to="/services/database" name="Database" class={hvc}>
          <CommonUI.Icons.Database class={["text-white"]} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/training" name="Training" class={hvc}>
          <CommonUI.Icons.Training class={["text-white"]} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/notebooks" name="Training" class={hvc}>
          <CommonUI.Icons.Notebook class={["text-white"]} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/monitoring" name="Monitoring" class={hvc}>
          <CommonUI.Icons.Monitoring class={["text-white"]} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/devtools" name="Devtools" class={hvc}>
          <CommonUI.Icons.Devtools class={["text-white"]} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/security" name="Security" class={hvc}>
          <CommonUI.Icons.Security class={["text-white"]} />
        </MobileMenuItem>
      </:mobile_menu>

      <:default>
        <#slot name="default" />
      </:default>
    </CommonUI.Layout>
    """
  end
end
