defmodule CommonUI.Components.Icon do
  @moduledoc false
  use CommonUI, :component

  attr :name, :atom, required: true
  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :rest, :global

  def icon(%{name: :github} = assigns), do: CommonUI.Icons.GitHub.icon(assigns)
  def icon(%{name: :kubernetes} = assigns), do: CommonUI.Icons.Kubernetes.icon(assigns)
  def icon(%{name: :slack} = assigns), do: CommonUI.Icons.Slack.icon(assigns)

  def icon(assigns), do: apply(Heroicons, assigns.name, [assigns])
end
