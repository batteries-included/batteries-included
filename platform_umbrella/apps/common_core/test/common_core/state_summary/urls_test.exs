defmodule CommonCore.StateSummary.URLsTest do
  use ExUnit.Case, async: true

  import CommonCore.StateSummary.URLs

  describe "uri_for_battery/2" do
    test "returns a host matching the host module" do
      summary = CommonCore.StateSummary.SeedState.seed(:everything)
      uri = uri_for_battery(summary, :smtp4dev)
      assert CommonCore.StateSummary.Hosts.for_battery(summary, :smtp4dev) == uri.host
    end

    test "returns an HTTPS URI when :cert_manager is installed" do
      summary = CommonCore.StateSummary.SeedState.seed(:everything)
      expected = URI.new!("https://keycloak.core.127.0.0.1.ip.batteriesincl.com")
      assert expected == uri_for_battery(summary, :keycloak)
    end

    test "returns an HTTP URI when :cert_manager is not installed" do
      summary = CommonCore.StateSummary.SeedState.seed(:dev)
      expected = URI.new!("http://forgejo.core.127.0.0.1.ip.batteriesincl.com")
      assert expected == uri_for_battery(summary, :forgejo)
    end
  end

  describe "keycloak_uri_for_realm/2" do
    test "returns the keycloak URI" do
      summary = CommonCore.StateSummary.SeedState.seed(:everything)
      expected = URI.new!("https://keycloak.core.127.0.0.1.ip.batteriesincl.com/realms/test-realm")
      assert expected == keycloak_uri_for_realm(summary, "test-realm")
    end
  end

  describe "cloud_native_pg_dashboard" do
    test "returns the cloud native pg dashboard URI" do
      summary = CommonCore.StateSummary.SeedState.seed(:everything)

      expected =
        URI.new!("https://grafana.core.127.0.0.1.ip.batteriesincl.com/d/cloudnative-pg/cloudnativepg")

      assert expected == cloud_native_pg_dashboard(summary)
    end
  end

  describe "pod_dashboard" do
    test "returns the pod dashboard URI" do
      summary = CommonCore.StateSummary.SeedState.seed(:everything)

      expected =
        URI.new!("https://grafana.core.127.0.0.1.ip.batteriesincl.com/d/k8s_views_pods/kubernetes-views-pods")

      assert expected == pod_dashboard(summary)
    end
  end
end
