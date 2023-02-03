defmodule CommonUI.LabeledDefiniton do
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
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
