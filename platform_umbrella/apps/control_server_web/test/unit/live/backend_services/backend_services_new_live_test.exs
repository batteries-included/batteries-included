defmodule ControlServerWeb.BackendServicesNewLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  describe "new" do
    test "can insert good params", %{conn: conn} do
      # There are only hidden inputs for these fields
      params = :backend_service |> params_for() |> Map.drop(~w(containers init_containers env_values)a)
      container = :containers_container |> params_for() |> Map.drop(~w(env_values)a)
      env_value = :containers_env_value |> params_for() |> Map.drop(~w(source_optional)a)

      conn
      |> start(~p|/backend_services/new|)
      |> click("button", "Add Container")
      |> submit_form("#container-form", container: container)
      |> click("button", "Add Variable")
      |> submit_form("#env_value-form", env_value: env_value)
      |> submit_form("#backend-service-form", service: params)
      |> follow()
      |> assert_html(params.name)
    end
  end
end
