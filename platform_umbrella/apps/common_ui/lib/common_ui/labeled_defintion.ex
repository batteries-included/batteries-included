defmodule CommonUI.LabeledDefiniton do
  use CommonUI.Component

  import CommonUI.Card

  def labeled_definition(assigns) do
    ~H"""
    <.card>
      <:title><%= @title %></:title>

      <%= @contents %>
    </.card>
    """
  end
end
