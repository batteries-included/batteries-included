defmodule KubeServices do
  @moduledoc """
  Documentation for `KubeServices`.
  """

  def start_apply do
    GenServer.cast(KubeServices.Worker, :apply)
  end

  def apply do
    GenServer.call(KubeServices.Worker, :apply_now, 10_000)
  end
end
