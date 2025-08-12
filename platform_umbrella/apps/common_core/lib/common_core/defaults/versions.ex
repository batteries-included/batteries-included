defmodule CommonCore.Defaults.Versions do
  @moduledoc false

  @stable_version "1.0.2"

  @spec bi_stable_version() :: String.t()
  def bi_stable_version, do: @stable_version
end
