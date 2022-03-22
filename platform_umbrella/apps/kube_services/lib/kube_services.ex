defmodule KubeServices do
  @moduledoc """
  Documentation for `KubeServices`.
  """

  def list_workers do
    Registry.select(
      KubeServices.Registry.Worker,
      [
        {{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}
      ]
    )
  end
end
