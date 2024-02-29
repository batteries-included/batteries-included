defmodule Storybook.Typography do
  @moduledoc false
  use PhoenixStorybook.Story, :page

  def render(assigns) do
    ~H"""
    <div class="psb-typography-page"></div>
    """
  end
end
