defmodule CommonUI.Table do
  use Phoenix.Component

  @table_class "min-w-full overflow-hidden divide-y divide-gray-200 rounded-sm table-auto"
  @thead_class ""
  @tbody_class ""
  @th_class "px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
  @tr_class "bg-white"
  @td_class "px-6 py-4 text-sm text-gray-500 whitespace-nowrap"

  def table(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:extra, fn ->
        assigns_to_attributes(assigns, [:class])
      end)

    default_class = @table_class

    ~H"""
    <table class={Enum.join([default_class, @class], " ")} {@extra}>
      <%= render_slot(@inner_block) %>
    </table>
    """
  end

  def thead(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:extra, fn ->
        assigns_to_attributes(assigns, [:class])
      end)

    default_class = @thead_class

    ~H"""
    <thead class={Enum.join([default_class, @class], " ")} {@extra}>
      <%= render_slot(@inner_block) %>
    </thead>
    """
  end

  def tbody(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:extra, fn ->
        assigns_to_attributes(assigns, [:class])
      end)

    default_class = @tbody_class

    ~H"""
    <tbody class={Enum.join([default_class, @class], " ")} {@extra}>
      <%= render_slot(@inner_block) %>
    </tbody>
    """
  end

  def th(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:extra, fn ->
        assigns_to_attributes(assigns, [:class])
      end)

    default_class = @th_class

    ~H"""
    <th class={Enum.join([default_class, @class], " ")} {@extra}>
      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </th>
    """
  end

  def tr(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:extra, fn ->
        assigns_to_attributes(assigns, [:class])
      end)

    default_class = @tr_class

    ~H"""
    <tr class={Enum.join([default_class, @class], " ")} {@extra}>
      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </tr>
    """
  end

  def td(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:extra, fn ->
        assigns_to_attributes(assigns, [:class])
      end)

    default_class = @td_class

    ~H"""
    <td class={Enum.join([default_class, @class], " ")} {@extra}>
      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </td>
    """
  end
end
