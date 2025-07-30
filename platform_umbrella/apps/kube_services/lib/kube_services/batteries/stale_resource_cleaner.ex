defmodule KubeServices.Batteries.StaleResourceCleaner do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  def init(opts) do
    battery = Keyword.fetch!(opts, :battery)

    children = [{KubeServices.Stale.Reaper, [delay: battery.config.delay]}]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
