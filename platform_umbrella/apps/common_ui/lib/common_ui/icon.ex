defmodule CommonUI.Icon do
  @moduledoc false
  use Phoenix.Component

  attr :name, :atom, required: true
  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :rest, :global

  def icon(assigns) do
    apply(Heroicons, assigns.name, [assigns])
  end
end
