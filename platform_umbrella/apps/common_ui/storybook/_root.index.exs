defmodule Storybook.Root do
  @moduledoc false
  use PhoenixStorybook.Index

  def folder_name, do: "Common UI"

  # Hide default storybook icon
  def folder_icon, do: {:fa, "", nil}
  def folder_index, do: 0

  # Name the page `_.story.exs` so it acts as the index
  def entry("_"), do: [name: "Welcome"]
end
