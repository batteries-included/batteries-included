defmodule ControlServerWeb.AIHomeTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  alias ControlServer.Batteries.Installer
  alias KubeServices.SystemState.Summarizer

  defp install_batteries(_) do
    notebooks_report = Installer.install!(:notebooks)
    %{notebooks: notebooks_report}
  end

  defp create_notebook(_) do
    %{notebook: insert(:jupyter_lab_notebook)}
  end

  defp summary(_) do
    %{summary: Summarizer.new()}
  end

  describe "AI home with batteries" do
    setup [:install_batteries, :create_notebook, :summary]

    test "contains links", %{conn: conn, notebook: notebook} do
      conn
      |> start("/ai")
      |> assert_html("AI")
      |> assert_html(notebook.name)
    end
  end

  describe "AI home with no batteries" do
    setup [:summary]

    test "contains empty home component", %{conn: conn} do
      conn
      |> start("/ai")
      |> assert_html("AI")
      |> assert_html("There are no batteries installed for this group.")
    end
  end
end
