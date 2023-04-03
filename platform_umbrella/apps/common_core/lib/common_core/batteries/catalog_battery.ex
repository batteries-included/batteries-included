defmodule CommonCore.Batteries.CatalogBattery do
  alias CommonCore.Batteries.SystemBattery

  @enforce_keys [:type, :group]
  defstruct type: nil,
            group: nil,
            dependencies: []

  def to_fresh_args(%__MODULE__{} = catalog_battery) do
    catalog_battery
    |> Map.from_struct()
    |> Map.put_new(:config, %{__type__: catalog_battery.type})
  end

  def to_fresh_system_battery(%__MODULE__{} = catalog_battery) do
    args =
      catalog_battery
      |> Map.from_struct()
      |> Map.drop([:__meta__, :__struct__, :id])
      |> Map.put_new(:config, %{__type__: catalog_battery.type})

    %SystemBattery{}
    |> SystemBattery.changeset(args)
    |> Ecto.Changeset.apply_action!(:create)
  end
end
