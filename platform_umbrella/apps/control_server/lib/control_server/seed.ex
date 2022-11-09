defmodule ControlServer.Seed do
  alias ControlServer.Batteries.Installer

  def seed_from_snapshot(snapshot) do
    snapshot.system_batteries
    |> Enum.map(fn battery -> {battery.type, Installer.install!(battery.type)} end)
    |> Map.new()
  end
end
