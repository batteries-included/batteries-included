defmodule KubeServices.SystemState.SummaryURLsTest do
  use ExUnit.Case, async: true

  alias KubeServices.SystemState.SummaryURLs
  alias KubeServices.SystemState.SummaryURLsTest

  setup do
    %{pid: start_supervised!({SummaryURLs, [name: SummaryURLsTest, subscribe: false]})}
  end

  describe "url_for_battery/2" do
    test "returns an HTTPS URL when :cert_manager is installed", %{pid: pid} do
      summary = CommonCore.StateSummary.SeedState.seed(:everything)
      send(pid, summary)

      assert "https://keycloak.core.127.0.0.1.ip.batteriesincl.com" == SummaryURLs.url_for_battery(pid, :keycloak)
      assert "https://gitea.core.127.0.0.1.ip.batteriesincl.com" == SummaryURLs.url_for_battery(pid, :gitea)
      assert "https://smtp4dev.core.127.0.0.1.ip.batteriesincl.com" == SummaryURLs.url_for_battery(pid, :smtp4dev)
    end

    test "returns an HTTP URL when :cert_manager is not installed", %{pid: pid} do
      summary = CommonCore.StateSummary.SeedState.seed(:dev)
      send(pid, summary)

      assert "http://keycloak.core.127.0.0.1.ip.batteriesincl.com" == SummaryURLs.url_for_battery(pid, :keycloak)
      assert "http://gitea.core.127.0.0.1.ip.batteriesincl.com" == SummaryURLs.url_for_battery(pid, :gitea)
      assert "http://smtp4dev.core.127.0.0.1.ip.batteriesincl.com" == SummaryURLs.url_for_battery(pid, :smtp4dev)
    end
  end

  describe "keycloak_url_for_realm/2" do
    test "returns keycloak URL for realm", %{pid: pid} do
      summary = CommonCore.StateSummary.SeedState.seed(:dev)
      send(pid, summary)

      assert "http://keycloak.core.127.0.0.1.ip.batteriesincl.com/realms/test-realm" ==
               SummaryURLs.keycloak_url_for_realm(pid, "test-realm")
    end
  end
end
