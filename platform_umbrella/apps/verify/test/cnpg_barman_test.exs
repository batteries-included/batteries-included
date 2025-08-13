defmodule Verify.CNPGBarmanTest do
  use Verify.Images

  use Verify.TestCase,
    async: false,
    batteries: ~w(cloudnative_pg_barman)a,
    images: ~w(cnpg_plugin_barman cnpg_plugin_barman_sidecar)a ++ @cert_manager

  setup_all %{control_url: url} do
    {:ok, session} = start_session(url)

    session
    |> assert_pods_in_deployment_running("battery-base", "cert-manager")
    |> assert_pods_in_deployment_running("battery-base", "cert-manager-cainjector")
    |> assert_pods_in_deployment_running("battery-base", "cert-manager-webhook")

    Wallaby.end_session(session)
  end

  verify "barman is running", %{session: session} do
    assert_pods_in_deployment_running(session, "battery-core", "barman-cloud")
  end
end
