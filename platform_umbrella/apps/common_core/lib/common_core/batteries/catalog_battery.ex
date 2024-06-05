defmodule CommonCore.Batteries.CatalogBattery do
  @moduledoc false
  use TypedStruct

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Ecto.BatteryUUID

  typedstruct do
    field :type, atom(), enforce: true
    field :group, atom(), enforce: true
    field :dependencies, list(atom()), default: []
    field :name, String.t(), enforce: true
    field :description, String.t(), default: ""
  end

  def to_fresh_args(%__MODULE__{} = catalog_battery) do
    catalog_battery
    |> Map.from_struct()
    |> Map.put_new(:config, %{:type => catalog_battery.type})
  end

  def to_fresh_system_battery(%__MODULE__{} = catalog_battery) do
    args =
      catalog_battery
      |> Map.from_struct()
      |> Map.drop([:__meta__, :__struct__, :id])
      |> Map.put_new(:config, %{:type => catalog_battery.type})
      |> Map.put(:id, BatteryUUID.autogenerate())

    %SystemBattery{}
    |> SystemBattery.changeset(args)
    |> Ecto.Changeset.apply_action!(:create)
  end
end
