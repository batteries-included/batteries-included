defmodule CommonCore.Resources.Istio.KialiConfigGeneratorTest do
  use ExUnit.Case, async: true

  import CommonCore.Factory

  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.Resources.Istio.KialiConfigGenerator
  alias CommonCore.StateSummary.Batteries

  describe "materialize/2" do
    test "sets namespaces from state" do
      state = build(:install_spec, usage: :kitchen_sink, kube_provider: :kind).target_summary
      batteries = Batteries.by_type(state)

      config = KialiConfigGenerator.materialize(batteries.kiali, state)
      assert config["istio_namespace"] == "battery-istio"
    end

    test "sets server config to https when :cert_manager is installed" do
      state = build(:install_spec, usage: :kitchen_sink, kube_provider: :aws).target_summary
      batteries = Batteries.by_type(state)

      config = KialiConfigGenerator.materialize(batteries.kiali, state)
      server = config["server"]
      assert server["web_port"] == 443
      assert server["web_scheme"] == "https"
    end

    test "sets server config to http when :cert_manager is not installed" do
      state = build(:install_spec, usage: :internal_int_test, kube_provider: :provided).target_summary

      batt =
        :kiali
        |> Catalog.get()
        |> CatalogBattery.to_fresh_system_battery()

      config = KialiConfigGenerator.materialize(batt, state)
      server = config["server"]
      assert server["web_port"] == 80
      assert server["web_scheme"] == "http"
    end
  end
end
