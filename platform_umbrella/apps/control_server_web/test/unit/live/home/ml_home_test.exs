defmodule ControlServerWeb.MLHomeTest do
  use Heyya.LiveTest
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  alias ControlServer.Batteries.Installer
  alias KubeServices.SystemState.Summarizer

  defp install_batteries(_) do
    notebooks_report = Installer.install!(:notebooks)
    %{notebooks: notebooks_report}
  end

  defp create_notebook(_) do
    %{notebook: insert(:jupyter_notebook)}
  end

  defp summary(_) do
    %{summary: Summarizer.new()}
  end

  describe "ML home with batteries" do
    setup [:install_batteries, :create_notebook, :summary]

    test "contains links", %{conn: conn, notebook: notebook} do
      conn
      |> start("/ml")
      |> assert_html("Machine Learning")
      |> assert_html(notebook.name)
    end
  end

  describe "ML home with no batteries" do
    setup [:summary]

    test "contains empty home component", %{conn: conn} do
      conn
      |> start("/ml")
      |> assert_html("Machine Learning")
      |> assert_html("There are no batteries installed for this group.")
    end
  end
end
