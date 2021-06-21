defmodule ControlServerWeb.Live.Layout do
  use Surface.Component

  alias CommonUI.Layout.MenuItem
  alias CommonUI.Layout.MobileMenuItem

  slot(default, required: true)

  @menu_item_class ["hover:bg-astral-100", "hover:text-pink-500", "text-gray-500"]
  @icon_class ["text-astral-500", "group-hover:text-pink-500"]

  def render(assigns) do
    mic = @menu_item_class
    ic = @icon_class

    ~F"""
    <CommonUI.Layout bg_class="bg-white">
      <:main_menu>
        <MenuItem to="/services/database" name="Databases" class={mic}>
          <CommonUI.Icons.Database class={ic} />
        </MenuItem>
        <MenuItem to="/services/training" name="Training" class={mic}>
          <CommonUI.Icons.Training class={ic} />
        </MenuItem>
        <MenuItem to="/services/notebooks" name="Notebooks" class={mic}>
          <CommonUI.Icons.Notebook class={ic} />
        </MenuItem>
        <MenuItem to="/services/monitoring" name="Monitoring" class={mic}>
          <CommonUI.Icons.Monitoring class={ic} />
        </MenuItem>
        <MenuItem to="/services/devtools" name="Devtools" class={mic}>
          <CommonUI.Icons.Devtools class={ic} />
        </MenuItem>
        <MenuItem to="/services/security" name="Security" class={mic}>
          <CommonUI.Icons.Security class={ic} />
        </MenuItem>
      </:main_menu>

      <:mobile_menu>
        <MobileMenuItem to="/services/database" name="Database" class={mic}>
          <CommonUI.Icons.Database class={ic} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/training" name="Training" class={mic}>
          <CommonUI.Icons.Training class={ic} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/notebooks" name="Training" class={mic}>
          <CommonUI.Icons.Notebook class={ic} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/monitoring" name="Monitoring" class={mic}>
          <CommonUI.Icons.Monitoring class={ic} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/devtools" name="Devtools" class={mic}>
          <CommonUI.Icons.Devtools class={ic} />
        </MobileMenuItem>
        <MobileMenuItem to="/services/security" name="Security" class={mic}>
          <CommonUI.Icons.Security class={ic} />
        </MobileMenuItem>
      </:mobile_menu>

      <:default>
        <#slot name="default" />
      </:default>
    </CommonUI.Layout>
    """
  end
end
