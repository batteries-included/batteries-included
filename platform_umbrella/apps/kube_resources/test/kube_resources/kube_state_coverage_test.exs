defmodule KubeServices.KubeStateCoverageTest do
  use ControlServer.DataCase

  alias KubeResources.ConfigGenerator
  alias ControlServer.Services.RunnableService
  alias ControlServer.Services
  alias KubeExt.ApiVersionKind

  require Logger

  @services [
    :data,
    :database,
    :database_internal,
    :battery,
    :control_server,
    :knative,
    :grafana,
    :kube_monitoring,
    :keycloak
  ]

  def assert_all_resources_watchable do
    Services.all_including_config()
    |> Enum.map(&ConfigGenerator.materialize/1)
    |> Enum.map(&KubeResources.unique_kinds/1)
    |> List.flatten()
    |> Enum.each(fn {api_version, kind} ->
      assert ApiVersionKind.is_watchable(api_version, kind),
             "Expected #{api_version} and #{kind} to be know types that can be watched by KubeState"
    end)
  end

  describe "KubeState can watch generated resources for the all inclusive setup" do
    setup do
      {:ok, runnable_service: Enum.map(@services, fn s -> RunnableService.activate!(s) end)}
    end

    test "Produces watchable types for kube state" do
      assert_all_resources_watchable()
    end
  end

  describe "KubeState can watch for every service" do
    test "All watchable" do
      Enum.each(
        RunnableService.services(),
        fn service ->
          RunnableService.activate!(service)

          assert_all_resources_watchable()
        end
      )
    end
  end
end
