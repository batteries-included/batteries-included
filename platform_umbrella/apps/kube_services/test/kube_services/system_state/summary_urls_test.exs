defmodule KubeServices.SystemState.SummaryURLsTest do
  use ExUnit.Case, async: true

  import CommonCore.Factory

  alias KubeServices.SystemState.SummaryURLs
  alias KubeServices.SystemState.SummaryURLsTest

  setup do
    %{pid: start_supervised!({SummaryURLs, [name: SummaryURLsTest, subscribe: false]})}
  end

  describe "url_for_battery/2" do
    test "returns an HTTPS URL when :cert_manager is installed", %{pid: pid} do
      spec = build(:install_spec, usage: :kitchen_sink, kube_provider: :aws)
      send(pid, spec.target_summary)

      assert "https://keycloak.127-0-0-1.batrsinc.co" == SummaryURLs.url_for_battery(pid, :keycloak)
      assert "https://forgejo.127-0-0-1.batrsinc.co" == SummaryURLs.url_for_battery(pid, :forgejo)
      assert "https://smtp4dev.127-0-0-1.batrsinc.co" == SummaryURLs.url_for_battery(pid, :smtp4dev)
    end

    test "returns an HTTP URL when :cert_manager is not installed", %{pid: pid} do
      spec = build(:install_spec, usage: :internal_int_test, kube_provider: :provided)
      send(pid, spec.target_summary)

      assert "http://keycloak.127-0-0-1.batrsinc.co" == SummaryURLs.url_for_battery(pid, :keycloak)
      assert "http://forgejo.127-0-0-1.batrsinc.co" == SummaryURLs.url_for_battery(pid, :forgejo)
      assert "http://smtp4dev.127-0-0-1.batrsinc.co" == SummaryURLs.url_for_battery(pid, :smtp4dev)
    end
  end

  describe "keycloak_url_for_realm/2" do
    test "returns keycloak URL for realm", %{pid: pid} do
      spec = build(:install_spec, usage: :kitchen_sink, kube_provider: :aws)
      send(pid, spec.target_summary)

      assert "https://keycloak.127-0-0-1.batrsinc.co/realms/test-realm" ==
               SummaryURLs.keycloak_url_for_realm(pid, "test-realm")
    end
  end
end
