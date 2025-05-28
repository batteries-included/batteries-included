defmodule ControlServerWeb.Projects.ProjectNewLiveTest do
  use ControlServerWeb.ConnCase
  use Heyya.LiveCase

  alias ControlServer.Batteries.Installer
  alias KubeServices.SystemState.Summarizer

  setup do
    %{install_result: Installer.install!(:battery_core), summarizer_result: Summarizer.new()}
  end

  describe "New Project" do
    test "import should be an option", %{conn: conn} do
      conn
      |> start(~p"/projects/new")
      |> assert_html("Tell More About Your Project")
      # Assert that there is an import option in the project type
      |> assert_element("select[name='project[type]'] option[value='import']")
      # Refute that theres a an option of notpresent option in the project type
      |> refute_element("select[name='project[type]'] option[value='notpresent']")
      |> submit_form("#project-form", project: %{type: :import, name: "Test Import Project"})
      |> assert_html("Snapshot Details")
    end
  end
end
