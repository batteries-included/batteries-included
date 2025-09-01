defmodule CommonCore.Redis.InstanceType do
  @moduledoc false

  use CommonCore.Ecto.Enum,
    standalone: "standalone",
    replication: "replication",
    sentinel: "sentinel",
    cluster: "cluster"

  @spec options() :: [{String.t(), String.t()}]
  def options do
    Enum.map(__enum_map__(), fn {_k, v} -> {String.capitalize(v), v} end)
  end
end
