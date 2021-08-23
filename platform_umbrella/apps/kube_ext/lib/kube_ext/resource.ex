defmodule KubeExt.Resource do
  def items(%{"items" => items}), do: items
  def items(_), do: []
end
