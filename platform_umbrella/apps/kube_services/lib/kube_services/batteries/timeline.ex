defmodule KubeServices.Batteries.Timeline do
  use KubeServices.Batteries.Supervisor

  def init(opts) do
    # we don't care about the battery currently.
    # Just start watching everything now.
    _battery = Keyword.fetch!(opts, :battery)

    children = [KubeServices.Timeline]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
