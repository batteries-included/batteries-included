defmodule ControlServer.Seed do
  alias ControlServer.Batteries.Installer

  def seed_from_snapshot(snapshot) do
    Installer.install_all(snapshot.batteries)
  end
end
