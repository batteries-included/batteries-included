defmodule Storybook.Components.Pagination do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Pagination.pagination/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          meta: %{
            has_previous_page?: false,
            has_next_page?: false,
            current_offset: 0,
            current_page: 1,
            page_size: 5,
            total_count: 50
          }
        }
      }
    ]
  end
end
