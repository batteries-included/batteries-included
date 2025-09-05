defmodule KubeServices.RoboSRE.Executor do
  @moduledoc false

  @callback execute(CommonCore.RoboSRE.Action.t()) :: {:ok, any()} | {:error, any()}
end
