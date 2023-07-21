defmodule PodLogs do
  @moduledoc """
  Documentation for `PodLogs`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> PodLogs.hello()
      :world

  """
  def hello do
    {:ok, _worker_pid} =
      PodLogs.Worker.start_link(namespace: "battery-base", name: "pg-control-0", target: self())

    Process.sleep(60_000)

    :world
  end
end
