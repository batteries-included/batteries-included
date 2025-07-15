defmodule ControlServerWeb.TraditionalServicesNewLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  describe "new" do
    test "can insert good params", %{conn: conn} do
      # There are only hidden inputs for these fields
      params =
        :traditional_service |> params_for() |> Map.drop(~w(containers init_containers env_values ports volumes mounts)a)

      container = :containers_container |> params_for() |> Map.drop(~w(env_values mounts)a)
      env_value = :containers_env_value |> params_for() |> Map.drop(~w(source_optional)a)
      port = :port |> params_for() |> Map.drop(~w(protocol)a)

      conn
      |> start(~p|/traditional_services/new|)
      |> click("#containers_panel-containers button", "Add Container")
      |> submit_form("#container-form", container: container)
      |> click("#containers_panel-init_containers button", "Add Container")
      |> submit_form("#container-form", container: container)
      |> click("button", "Add Variable")
      |> submit_form("#env_value-form", env_value: env_value)
      |> click("button", "Add Port")
      |> submit_form("#port-form", port: port)
      |> submit_form("#traditional-service-form", service: params)
      |> follow()
      |> assert_html(params.name)
    end
  end
end
