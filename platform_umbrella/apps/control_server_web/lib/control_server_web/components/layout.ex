defmodule ControlServerWeb.Layout do
  use Surface.Component

  alias CommonUI.Layout.MenuItem

  slot default, required: true
  slot title

  @menu_item_class ["hover:bg-astral-100", "hover:text-pink-500", "text-gray-500"]
  @icon_class ["text-astral-500", "group-hover:text-pink-500"]

  prop container_type, :atom, default: :default

  def render(assigns) do
    mic = @menu_item_class
    ic = @icon_class

    ~F"""
    <CommonUI.Layout bg_class="bg-white" container_type={@container_type}>
      <:title>
        <#slot name="title">
        </#slot>
      </:title>
      <:main_menu>
        <MenuItem to="/services/database" name="Databases" class={mic}>
          <CommonUI.Icons.Database class={ic} />
        </MenuItem>
        <MenuItem to="/services/ml/training" name="Training" class={mic}>
          <CommonUI.Icons.Training class={ic} />
        </MenuItem>
        <MenuItem to="/services/ml/notebooks" name="Notebooks" class={mic}>
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
        <MenuItem to="/services/network" name="Network" class={mic}>
          <CommonUI.Icons.Network class={ic} />
        </MenuItem>
      </:main_menu>

      <:default>
        <#slot name="default" />
      </:default>
    </CommonUI.Layout>
    """
  end
end
