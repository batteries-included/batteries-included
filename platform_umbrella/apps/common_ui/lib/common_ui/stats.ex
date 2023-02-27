defmodule CommonUI.Stats do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]

  import CommonUI.Card
  import CommonUI.Typogoraphy

  def stats(assigns) do
    assigns = assign_new(assigns, :inner_block, fn -> nil end)

    ~H"""
    <.card>
      <%= if @inner_block do %>
        <div class="flex flex-row justify-around">
          <%= render_slot(@inner_block) %>
        </div>
      <% end %>
    </.card>
    """
  end

  def stat(assigns) do
    assigns = assign_new(assigns, :inner_block, fn -> nil end)

    ~H"""
    <div class="flex flex-col items-center">
      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </div>
    """
  end

  def stat_title(assigns) do
    assigns = assign_new(assigns, :inner_block, fn -> nil end)

    ~H"""
    <.h2>
      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </.h2>
    """
  end

  def stat_value(assigns) do
    assigns = assign_new(assigns, :inner_block, fn -> nil end)

    ~H"""
    <div class="text-base">
      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </div>
    """
  end

  def stat_description(assigns) do
    assigns = assign_new(assigns, :inner_block, fn -> nil end)

    ~H"""
    <div class="text-xs">
      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </div>
    """
  end
end
