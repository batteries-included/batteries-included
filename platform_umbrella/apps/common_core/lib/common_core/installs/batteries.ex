defmodule CommonCore.Installs.Batteries do
  @moduledoc false

  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Installation

  @standard_battery_types ~w(battery_core cloudnative_pg istio istio_gateway stale_resource_cleaner)a

  @kind_battery_types ~w(metallb)a
  @aws_only_battery_types ~w(aws_load_balancer_controller karpenter)a
  @aws_battery_types ~w(battery_ca)a ++ @aws_only_battery_types

  @internal_int_test_battery_types ~w(
    battery_core
    cloudnative_pg
    istio_gateway
    metallb
  )a
  @internal_prod_battery_types ~w(ferretdb traditional_services victoria_metrics grafana cloudnative_pg_barman)a

  @production_battery_types ~w(kube_monitoring timeline victoria_metrics grafana cloudnative_pg_barman)a
  @secure_battery_types ~w(keycloak)a

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
    |> enrich_all_battery_configs(install)
  end

  defp recursive_batteries(types) do
    types
    |> Enum.map(&Catalog.get/1)
    |> Enum.flat_map(&Catalog.get_recursive/1)
    |> Enum.map(&CatalogBattery.to_fresh_system_battery/1)
    |> Enum.uniq_by(& &1.type)
  end

  defp battery_types(install) do
    install
    |> provider_batteries()
    |> usage_batteries(install)
  end

  defp provider_batteries(%{kube_provider: :kind} = _install), do: @kind_battery_types
  defp provider_batteries(%{kube_provider: :aws} = _install), do: @aws_battery_types
  defp provider_batteries(%{kube_provider: _} = _install), do: []

  defp usage_batteries(_batteries, %Installation{usage: :internal_int_test} = _install) do
    # Internal int test is a special case where we want total control
    @internal_int_test_battery_types
  end

  defp usage_batteries(batteries, %Installation{usage: :internal_prod} = _install) do
    batteries ++ @standard_battery_types ++ @internal_prod_battery_types
  end

  defp usage_batteries(batteries, %Installation{usage: :production} = _install) do
    batteries ++ @standard_battery_types ++ @production_battery_types
  end

  defp usage_batteries(batteries, %Installation{usage: :secure_production} = _install) do
    batteries ++ @standard_battery_types ++ @production_battery_types ++ @secure_battery_types
  end

  defp usage_batteries(_batteries, %Installation{usage: :kitchen_sink, kube_provider: :aws} = _install) do
    # AWS Doesn't work with metallb since that requires icmp broadcast to affect layer 2 routing
    # and AWS doesn't support that.
    Catalog.all()
    |> Enum.reject(fn cb -> cb.type in [:metallb] end)
    |> Enum.map(fn cb -> cb.type end)
  end

  defp usage_batteries(_batteries, %Installation{usage: :kitchen_sink, kube_provider: _} = _install) do
    Catalog.all()
    |> Enum.reject(fn cb -> cb.type in @aws_only_battery_types end)
    |> Enum.map(fn cb -> cb.type end)
  end

  defp usage_batteries(batteries, _install) do
    batteries ++ @standard_battery_types
  end

  defp enrich_all_battery_configs(batteries, %Installation{} = install) do
    Enum.map(batteries, &enrich_single_battery_config(&1, install))
  end

  defp enrich_single_battery_config(%SystemBattery{type: :battery_core, config: config} = sb, %Installation{
         id: id,
         slug: slug,
         kube_provider: cluster_type,
         default_size: default_size,
         usage: usage,
         control_jwk: control_jwk
       }) do
    new_config = %{
      config
      | cluster_type: cluster_type,
        default_size: default_size,
        cluster_name: slug,
        install_id: id,
        control_jwk: control_jwk,
        usage: usage
    }

    %{sb | config: new_config}
  end

  defp enrich_single_battery_config(battery, _install) do
    battery
  end
end
