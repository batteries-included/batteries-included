defmodule ControlServerWeb.Layout do
  use Phoenix.Component

  alias CommonUI.Layout, as: BaseLayout

  @default_menu_item_class ["hover:bg-astral-100", "hover:text-pink-500", "text-gray-500"]
  @default_icon_class ["text-astral-500", "group-hover:text-pink-500"]

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:menu_item_class, fn -> @default_menu_item_class end)
    |> assign_new(:icon_class, fn -> @default_icon_class end)
    |> assign_new(:container_type, fn -> :default end)
    |> assign_new(:title, fn -> [] end)
  end

  defdelegate title(assigns), to: BaseLayout

  def layout(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <BaseLayout.layout bg_class="bg-white" container_type={@container_type}>
      <:title>
        <%= render_slot(@title) %>
      </:title>
      <:main_menu>
        <BaseLayout.menu_item to="/services/database" name="Databases" class={@menu_item_class}>
          <CommonUI.Icons.Database.render class={@icon_class} />
        </BaseLayout.menu_item>
        <BaseLayout.menu_item to="/services/ml/notebooks" name="Notebooks" class={@menu_item_class}>
          <CommonUI.Icons.Notebook.render class={@icon_class} />
        </BaseLayout.menu_item>
        <BaseLayout.menu_item to="/services/monitoring" name="Monitoring" class={@menu_item_class}>
          <CommonUI.Icons.Monitoring.render class={@icon_class} />
        </BaseLayout.menu_item>
        <BaseLayout.menu_item to="/services/devtools" name="Devtools" class={@menu_item_class}>
          <CommonUI.Icons.Devtools.render class={@icon_class} />
        </BaseLayout.menu_item>
        <BaseLayout.menu_item to="/services/security" name="Security" class={@menu_item_class}>
          <CommonUI.Icons.Security.render class={@icon_class} />
        </BaseLayout.menu_item>
        <BaseLayout.menu_item to="/services/network" name="Network" class={@menu_item_class}>
          <CommonUI.Icons.Network.render class={@icon_class} />
        </BaseLayout.menu_item>
      </:main_menu>
      <%= render_slot(@inner_block) %>
    </BaseLayout.layout>
    """
  end
end
