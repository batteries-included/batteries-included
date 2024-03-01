defmodule CommonUI.Components.Icon do
  @moduledoc false
  use CommonUI, :component

  attr :name, :atom, required: true
  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :rest, :global

  def icon(%{name: :battery} = assigns), do: CommonUI.Icons.Battery.icon(assigns)

  def icon(assigns), do: apply(Heroicons, assigns.name, [assigns])
end
