defmodule Storybook.Components.Fieldset do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Fieldset.fieldset/1
  def imports, do: [{CommonUI.Components.Field, field: 1}, {CommonUI.Components.Button, button: 1}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          flash: %{"info" => "Flash info"}
        },
        slots: [
          ~s|<.field><:label>Label</:label> <div class="bg-gray-200 h-8" /></.field>|,
          ~s|<.field><:label>Label</:label> <div class="bg-gray-200 h-8" /></.field>|,
          ~s|<.field><:label>Label</:label> <div class="bg-gray-200 h-8" /></.field>|,
          ~s|<.field><:label>Label</:label> <div class="bg-gray-200 h-8" /></.field>|,
          ~s"""
          <:actions>
            <.button variant="secondary">Cancel</.button>
            <.button variant="primary">Save</.button>
          </:actions>
          """
        ]
      },
      %Variation{
        id: :responsive,
        attributes: %{
          responsive: true,
          flash: %{"info" => "Flash info"}
        },
        slots: [
          ~s|<.field><:label>Label</:label> <div class="bg-gray-200 h-8" /></.field>|,
          ~s|<.field><:label>Label</:label> <div class="bg-gray-200 h-8" /></.field>|,
          ~s|<.field><:label>Label</:label> <div class="bg-gray-200 h-8" /></.field>|,
          ~s|<.field><:label>Label</:label> <div class="bg-gray-200 h-8" /></.field>|
        ]
      }
    ]
  end
end
