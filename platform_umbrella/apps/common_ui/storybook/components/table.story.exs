defmodule Storybook.Components.Table do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Table.table/1
  def container, do: {:div, class: "w-full p-2"}

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          rows: [
            %{id: 1, name: "Jane Doe", email: "jane@doe.com"},
            %{id: 2, name: "John Doe", email: "john@doe.com"}
          ]
        },
        slots: [
          ~s|<:col :let={row} label="ID"><%= row.id %></:col>|,
          ~s|<:col :let={row} label="Name"><%= row.name %></:col>|,
          ~s|<:col :let={row} label="Email"><%= row.email %></:col>|
        ]
      }
    ]
  end
end
