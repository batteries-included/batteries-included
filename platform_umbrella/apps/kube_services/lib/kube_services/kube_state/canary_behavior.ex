defmodule KubeServices.KubeState.Canary.Behaviour do
  @moduledoc """
  Behaviour for KubeState.Canary modules.
  """

  @callback force_restart() :: any()
end
