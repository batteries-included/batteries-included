defmodule ControlServerWeb.Knative.KnativeEditLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  describe "edit" do
    test "can can show the edit page", %{conn: conn} do
      service = insert(:knative_service)

      conn
      |> start(~p|/knative/services/#{service.id}/edit|)
      |> assert_html(service.name)
    end
  end

  describe "new" do
    test "can create a new service", %{conn: conn} do
      project = insert(:project)

      params =
        :knative_service
        |> params_for(project_id: project.id)
        |> Map.drop(~w(containers init_containers env_values kube_internal oauth2_proxy)a)

      conn
      |> start(~p|/knative/services/new|)
      |> submit_form("#service-form", service: params)
      |> follow()
      |> assert_html(params.name)
    end
  end
end
