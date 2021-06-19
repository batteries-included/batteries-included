defmodule ControlServerWeb.Live.Layout do
  use Surface.Component

  alias CommonUI.Layout.MenuItem
  alias CommonUI.Layout.MobileMenuItem

  slot(default, required: true)

  @hover_classes ["hover:bg-astral-100", "hover:text-pink-500", "text-gray-400"]
  @icon_classes ["text-astral-500", "group-hover:text-pink-500"]

  def render(assigns) do
    hvc = @hover_classes
    ivc = @icon_classes

    ~F"""
    <CommonUI.Layout bg_class="bg-white">
      <:main_menu>
        <MenuItem to="/services/database" name="Databases" class={hvc}>
          <CommonUI.Icons.Database class={ivc} />
        </MenuItem>
        <MenuItem to="/services/training" name="Training" class={hvc}>
          <CommonUI.Icons.Training class={ivc} />
        </MenuItem>
        <MenuItem to="/services/notebooks" name="Notebooks" class={hvc}>
          <CommonUI.Icons.Notebook class={ivc} />
        </MenuItem>
        <MenuItem to="/services/monitoring" name="Monitoring" class={hvc}>
          <CommonUI.Icons.Monitoring class={ivc} />
        </MenuItem>
        <MenuItem to="/services/devtools" name="Devtools" class={hvc}>
          <CommonUI.Icons.Devtools class={ivc} />
        </MenuItem>
        <MenuItem to="/services/security" name="Security" class={hvc}>
          <CommonUI.Icons.Security class={ivc} />
        </MenuItem>
      </:main_menu>

      <:mobile_menu>
        <MobileMenuItem to="/services/database" name="Database" class={hvc}>
          <CommonUI.Icons.Database class={ivc} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/training" name="Training" class={hvc}>
          <CommonUI.Icons.Training class={ivc} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/notebooks" name="Training" class={hvc}>
          <CommonUI.Icons.Notebook class={ivc} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/monitoring" name="Monitoring" class={hvc}>
          <CommonUI.Icons.Monitoring class={ivc} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/devtools" name="Devtools" class={hvc}>
          <CommonUI.Icons.Devtools class={ivc} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/security" name="Security" class={hvc}>
          <CommonUI.Icons.Security class={ivc} />
        </MobileMenuItem>
      </:mobile_menu>

      <:default>
        <#slot name="default" />
      </:default>
    </CommonUI.Layout>
    """
  end
end
