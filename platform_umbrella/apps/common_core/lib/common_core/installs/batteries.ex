defmodule CommonCore.Installs.Batteries do
  @moduledoc false

  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Installation

  @standard_battery_types ~w(battery_core cloudnative_pg istio istio_gateway stale_resource_cleaner)

  def default_batteries(%Installation{} = install) do
    install
    |> battery_types()
    |> recursive_batteries()
    # All the batteries have default configs
    # Pass the settings from install into the batteries that will eventually
    # run on the control server
    |> add_battery_core_config(install)
  end

  defp add_battery_core_config(batteries, %Installation{kube_provider: cluster_type, default_size: default_size}) do
    Enum.map(batteries, fn
      %SystemBattery{type: :battery_core, config: config} = sb ->
        %SystemBattery{sb | config: %BatteryCoreConfig{config | cluster_type: cluster_type, default_size: default_size}}

      battery ->
        battery
    end)
  end

  defp recursive_batteries(types) do
    types
    |> Enum.map(&Catalog.get/1)
    |> Enum.flat_map(&Catalog.get_recursive/1)
    |> Enum.map(&CatalogBattery.to_fresh_system_battery/1)
    |> Enum.uniq_by(& &1.type)
  end

  defp battery_types(%Installation{kube_provider: kube_provider} = install) do
    case kube_provider do
      :kind -> kind_batteries(install)
      :aws -> aws_batteries(install)
      :provided -> provided_batteries(install)
    end
  end

  defp kind_batteries(install) do
    case install.usage do
      # We have a special case where kind is used for integration tests
      # that needs to be slim for now to keep GH's runners happy. They run on fucking potatos.
      :internal_int_test ->
        ~w(battery_core)a

      :internal_dev ->
        ~w(metallb)a ++ @standard_battery_types

      :kitchen_sink ->
        # This is a kind cluster so no aws things are going to work.
        Catalog.all()
        |> Enum.reject(fn cb -> cb.type in [:karpenter, :aws_load_balancer] end)
        |> Enum.map(fn cb -> cb.type end)

      _ ->
        # TODO: This should include a control server.
        ~w(metallb)a ++ @standard_battery_types
    end
  end

  defp aws_batteries(install) do
    case install.usage do
      :internal_dev ->
        ~w(karpenter battery_ca aws_load_balancer_controller) ++ @standard_battery_types

      :kitchen_sink ->
        # AWS doesn't work with some batteries
        Catalog.all()
        |> Enum.reject(fn cb -> cb.type in [:metallb] end)
        |> Enum.map(fn cb -> cb.type end)

      _ ->
        # TODO: This should include a control server.
        ~w(karpenter battery_ca aws_load_balancer_controller) ++ @standard_battery_types
    end
  end

  defp provided_batteries(_install) do
    @standard_battery_types
  end
end