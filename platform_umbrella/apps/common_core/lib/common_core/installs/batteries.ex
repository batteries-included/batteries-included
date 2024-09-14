defmodule CommonCore.Installs.Batteries do
  @moduledoc false

  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Installation

  @standard_battery_types ~w(battery_core cloudnative_pg istio istio_gateway stale_resource_cleaner)
  @aws_battery_types ~w(karpenter battery_ca aws_load_balancer_controller)

  def default_batteries(%Installation{} = install) do
    # TODO: This is utter shit. I should have done better
    #
    # We need to create all the SystemBatteries that
    # are specialized from the install (probably in
    # a map by type). Then use that as the base to
    # accumulate all the required types and their
    # depdendencies.
    install
    |> battery_types()
    |> recursive_batteries()
    # All the batteries have default configs
    # Pass the settings from install into the batteries that will eventually
    # run on the control server
    |> add_battery_core_config(install)
  end

  defp add_battery_core_config(batteries, %Installation{
         id: id,
         slug: slug,
         kube_provider: cluster_type,
         default_size: default_size,
         usage: usage,
         control_jwk: control_jwk
       }) do
    Enum.map(batteries, fn
      %SystemBattery{type: :battery_core, config: config} = sb ->
        new_config = %BatteryCoreConfig{
          config
          | cluster_type: cluster_type,
            default_size: default_size,
            cluster_name: slug,
            install_id: id,
            control_jwk: control_jwk,
            usage: usage
        }

        %SystemBattery{sb | config: new_config}

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
        ~w(battery_core cloudnative_pg istio_gateway metallb traditional_services)a

      :internal_prod ->
        ~w(metallb traditional_services)a ++ @standard_battery_types

      :kitchen_sink ->
        # This is a kind cluster so no aws things are going to work.
        Catalog.all()
        |> Enum.reject(fn cb -> cb.type in [:karpenter, :aws_load_balancer] end)
        |> Enum.map(fn cb -> cb.type end)

      _ ->
        ~w(metallb)a ++ @standard_battery_types
    end
  end

  defp aws_batteries(install) do
    case install.usage do
      :internal_prod ->
        ~w(traditional_services)a ++ @aws_battery_types ++ @standard_battery_types

      :kitchen_sink ->
        # AWS doesn't work with some batteries
        Catalog.all()
        |> Enum.reject(fn cb -> cb.type in [:metallb] end)
        |> Enum.map(fn cb -> cb.type end)

      _ ->
        @aws_battery_types ++ @standard_battery_types
    end
  end

  defp provided_batteries(install) do
    case install.usage do
      :kitchen_sink ->
        # AWS doesn't work with some batteries
        Catalog.all()
        |> Enum.reject(fn cb -> cb.type in [:metallb] end)
        |> Enum.map(fn cb -> cb.type end)

      _ ->
        @standard_battery_types
    end
  end
end
