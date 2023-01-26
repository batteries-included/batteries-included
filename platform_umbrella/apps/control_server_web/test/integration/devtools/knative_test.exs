defmodule ControlServerWeb.Integration.Knative do
  use ControlServerWeb.IntegrationTestCase

  require Logger

  @button_text "New Knative Service"
  @base_service_name "knative-integration-test"
  @image "registry.k8s.io/kubernetes-e2e-test-images/echoserver:2.2"

  @root_url "/services/devtools/knative_services"

  feature "Can create a knative server", %{session: session} do
    Logger.warn("XXXXXXXXXX Starting knative test")
    EventCenter.KubeState.subscribe(:knative_serving)

    service_name = service_name()

    session
    |> visit(@root_url)
    |> refute_has(css("tr td"))
    |> click(link(@button_text))
    |> fill_in(text_field("service[name]"), with: service_name)
    |> fill_in(text_field("service[image]"), with: @image)
    |> click(button("Save"))
    |> assert_has(css("tr td", count: nil, minimum: 1))
    |> assert_text(service_name)

    assert_receive _, 240_000
  end

  defp service_name, do: "#{@base_service_name}-#{:rand.uniform(10000)}"
end
