defmodule KubeServices.Batteries.StaleResourceCleaner do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  def init(opts) do
    _battery = Keyword.fetch!(opts, :battery)

    children = [KubeServices.Stale.Reaper]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
