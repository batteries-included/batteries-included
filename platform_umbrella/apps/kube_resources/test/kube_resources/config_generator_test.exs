defmodule KubeServices.ConfigGeneratorTest do
  use ControlServer.DataCase

  alias KubeResources.ConfigGenerator
  alias ControlServer.Services

  require Logger

  describe "ConfigGenerator" do
    setup do
      {:ok,
       prometheus_operator: Services.PrometheusOperator.activate!(),
       prometheus: Services.Prometheus.activate!(),
       grafana: Services.Grafana.activate!(),
       knative: Services.Knative.activate!(),
       database: Services.Database.activate!(),
       database_internal: Services.InternalDatabase.activate!(),
       cert_manager: Services.CertManager.activate!()}
    end

    test "materialize all the configs" do
      Services.list_base_services()
      |> Enum.each(fn service ->
        configs = ConfigGenerator.materialize(service)

        assert map_size(configs) >= 1
      end)
    end

    test "everything can turn into json" do
      Services.list_base_services()
      |> Enum.each(fn base_service ->
        configs = ConfigGenerator.materialize(base_service)

        {res, _value} = Jason.encode(configs)

        assert :ok == res
      end)
    end
  end
end
