defmodule Verify.CertManagerTest do
  use Verify.TestCase, async: false, batteries: ~w(cert_manager trust_manager istio_csr battery_ca)a

  verify "cert_manager is running", %{session: session} do
    session
    |> assert_pods_in_deployment_running("battery-base", "cert-manager")
    |> assert_pods_in_deployment_running("battery-base", "cert-manager-cainjector")
    |> assert_pods_in_deployment_running("battery-base", "cert-manager-webhook")
  end

  verify "istio_csr is running", %{session: session} do
    assert_pods_in_deployment_running(session, "battery-base", "cert-manager-istio-csr")
  end

  verify "trust_manager is running", %{session: session} do
    assert_pods_in_deployment_running(session, "battery-base", "trust-manager")
  end

  # TODO: check battery_ca issuer
end
