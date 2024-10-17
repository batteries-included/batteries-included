defmodule Storybook.Components.Field do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Field.field/1
  def imports, do: [{CommonUI.Components.Link, a: 1}]

  def variations do
    [
      %Variation{
        id: :stacked,
        slots: [
          ~s|<:label help="This is some help text">Label</:label>|,
          ~s|<div class="bg-gray-200 h-8" />|,
          ~s|<:note>This is a note</:note>|
        ]
      },
      %Variation{
        id: :custom_label,
        slots: [
          ~s|<:label help="This is some help text">Label <.a href="#">with link</.a></:label>|,
          ~s|<div class="bg-gray-200 h-8" />|,
          ~s|<:note>This is a note</:note>|
        ]
      },
      %Variation{
        id: :custom_note,
        slots: [
          ~s|<:label help="This is some help text">Label</:label>|,
          ~s|<div class="bg-gray-200 h-8" />|,
          ~s|<:note>This is a note <.a href="#">with a link</.a></:note>|
        ]
      },
      %Variation{
        id: :beside,
        slots: [
          ~s|<:label help="This is some help text">Label</:label>|,
          ~s|<div class="bg-gray-200 h-8" />|,
          ~s|<:note>This is a note</:note>|
        ],
        attributes: %{
          variant: "beside"
        }
      }
    ]
  end
end
