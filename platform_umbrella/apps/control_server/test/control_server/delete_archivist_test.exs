defmodule ControlServer.DeleteArchivistTest do
  use ControlServer.DataCase

  alias CommonCore.Resources.Builder, as: B
  alias ControlServer.ContentAddressable
  alias ControlServer.Deleted.DeleteArchivist

  defp build_resource do
    :deployment
    |> B.build_resource()
    |> B.app_labels("test-app")
    |> B.name("test-deployment")
    |> B.namespace("battery-core")
  end

  describe "ControlServer.DeleteArchivist" do
    test "Will only create one content addressable" do
      res = build_resource()

      {:ok, _} = DeleteArchivist.record_delete(res)
      {:ok, _} = DeleteArchivist.record_delete(res)

      assert 1 == ContentAddressable.count_documents()
    end
  end
end
