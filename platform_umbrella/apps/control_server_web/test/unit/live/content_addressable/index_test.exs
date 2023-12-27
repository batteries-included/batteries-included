defmodule ControlServerWeb.Live.ContentAddressable.IndexTest do
  use Heyya.LiveTest
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  alias KubeServices.SystemState.Summarizer

  defp cas_documents(_) do
    %{cas_documents: Enum.map(0..5, fn _ -> insert(:content_addressable_document) end)}
  end

  defp summary(_) do
    %{summary: Summarizer.new()}
  end

  describe "content addressable index with resources" do
    setup [:cas_documents, :summary]

    test "contains resource links", %{conn: conn, cas_documents: cas_documents} do
      conn
      |> start("/content_addressable")
      |> assert_html("Content Addressable Storage")
      |> assert_html(cas_documents |> hd() |> Map.get(:hash))
    end
  end
end
