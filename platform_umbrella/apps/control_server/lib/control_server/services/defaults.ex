defmodule ControlServer.Services.Defaults do
  alias ControlServer.Services.Battery
  alias ControlServer.Services.Network

  def start do
    Task.Supervisor.start_child(
      ControlServer.TaskSupervisor,
      fn ->
        Enum.each([Battery, Network], fn def_mod -> def_mod.activate!() end)
        :ok
      end,
      restart: :transient
    )
  end
end
