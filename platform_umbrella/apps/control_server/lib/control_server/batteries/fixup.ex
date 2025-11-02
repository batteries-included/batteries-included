defmodule ControlServer.Batteries.Fixup do
  @moduledoc false

  def install_needed do
    # For every installed battery look at the catalog and make sure that all of it's dependencies are installed.
    # Any that are not installed will be installed with the ControlServer.Batteries.Installer module.

    Enum.each(ControlServer.Batteries.list_system_batteries(), fn system_battery ->
      {:ok, _} = ControlServer.Batteries.Installer.install(system_battery.type)
    end)

    :ok
  end
end
