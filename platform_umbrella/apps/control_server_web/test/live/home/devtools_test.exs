defmodule ControlServerWeb.DevtoolsHomeTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  alias ControlServer.Batteries.Installer
  alias KubeServices.SystemState.Summarizer

  defp install_batteries(_) do
    knative_report = Installer.install!(:knative)
    forgejo_report = Installer.install!(:forgejo)
    %{knative: knative_report, forgejo: forgejo_report}
  end

  defp knative_service(_) do
    %{service: insert(:knative_service)}
  end

  defp summary(_) do
    %{summary: Summarizer.new()}
  end

  describe "devtools home with batteries" do
    setup [:install_batteries, :knative_service, :summary]

    test "contains service links", %{conn: conn, service: service} do
      conn
      |> start("/devtools")
      |> assert_html("Devtools")
      |> assert_html(service.name)
    end

    test "contains forgejo link", %{conn: conn} do
      conn
      |> start("/devtools")
      |> assert_html("Devtools")
      |> assert_html("Forgejo")
    end
  end

  describe "devtools with no batteries" do
    setup [:summary]

    test "contains empty home component", %{conn: conn} do
      conn
      |> start("/devtools")
      |> assert_html("Devtools")
      |> assert_html("There are no batteries installed for this group.")
      |> assert_html("/batteries/devtools")
      |> refute_html("/batteries/monitoring")
      |> refute_html("/batteries/net_sec")
    end
  end
end
