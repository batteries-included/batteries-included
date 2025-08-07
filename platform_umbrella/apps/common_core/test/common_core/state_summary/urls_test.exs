defmodule CommonCore.StateSummary.URLsTest do
  use ExUnit.Case, async: true

  import CommonCore.Factory
  import CommonCore.StateSummary.URLs

  describe "uri_for_battery/2" do
    test "returns a host matching the host module" do
      summary = build(:install_spec).target_summary
      uri = uri_for_battery(summary, :keycloak)
      assert CommonCore.StateSummary.Hosts.for_battery(summary, :keycloak) == uri.host
    end

    test "returns an HTTPS URI when :cert_manager is installed" do
      summary = build(:install_spec, usage: :kitchen_sink, kube_provider: :provided).target_summary
      expected = URI.new!("https://keycloak.127-0-0-1.batrsinc.co")
      assert expected == uri_for_battery(summary, :keycloak)
    end

    test "returns an HTTP URI when :cert_manager is not installed" do
      summary = build(:install_spec, usage: :internal_int_test, kube_provider: :provided).target_summary
      expected = URI.new!("http://forgejo.127-0-0-1.batrsinc.co")
      assert expected == uri_for_battery(summary, :forgejo)
    end

    test "returns an HTTP URI on Kind" do
      summary = build(:install_spec, usage: :kitchen_sink, kube_provider: :kind).target_summary
      expected = URI.new!("http://keycloak.127-0-0-1.batrsinc.co")
      assert expected == uri_for_battery(summary, :keycloak)
    end
  end

  describe "keycloak_uri_for_realm/2" do
    test "returns the keycloak URI" do
      summary = build(:install_spec, usage: :kitchen_sink, kube_provider: :aws).target_summary
      expected = URI.new!("https://keycloak.127-0-0-1.batrsinc.co/realms/test-realm")
      assert expected == keycloak_uri_for_realm(summary, "test-realm")
    end
  end

  describe "cloud_native_pg_dashboard" do
    test "returns the cloud native pg dashboard URI" do
      summary = build(:install_spec, usage: :kitchen_sink, kube_provider: :aws).target_summary

      expected =
        URI.new!("https://grafana.127-0-0-1.batrsinc.co/d/cloudnative-pg/cloudnativepg")

      assert expected == cloud_native_pg_dashboard(summary)
    end

    test "returns the cloud native pg dashboard URI as http for kind" do
      summary = build(:install_spec, usage: :kitchen_sink, kube_provider: :kind).target_summary

      expected =
        URI.new!("http://grafana.127-0-0-1.batrsinc.co/d/cloudnative-pg/cloudnativepg")

      assert expected == cloud_native_pg_dashboard(summary)
    end
  end

  describe "pod_dashboard" do
    test "returns the pod dashboard URI" do
      summary = build(:install_spec, usage: :kitchen_sink, kube_provider: :aws).target_summary

      expected =
        URI.new!("https://grafana.127-0-0-1.batrsinc.co/d/k8s_views_pods/kubernetes-views-pods")

      assert expected == pod_dashboard(summary)
    end
  end
end
