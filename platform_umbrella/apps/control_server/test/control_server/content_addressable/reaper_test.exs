defmodule ControlServer.ContentAddressable.ReaperTest do
  use ControlServer.DataCase

  import ControlServer.Factory

  alias ControlServer.ContentAddressable.Document
  alias ControlServer.ContentAddressable.Reap
  alias ControlServer.Repo

  describe "Reap.reap_unused_documents/1" do
    test "leaves new documents alone" do
      document = insert(:content_addressable_document)
      assert Reap.reap_unused_documents() == 0
      # This document shoudl be fine since the document is new
      assert Repo.get!(Document, document.id)
    end

    test "Removes old documents" do
      document = insert(:content_addressable_document, inserted_at: DateTime.add(DateTime.utc_now(), -91, :second))
      assert Reap.reap_unused_documents() == 1
      assert Repo.get(Document, document.id) == nil
    end

    test "doesnt remove referenced rows" do
      document = insert(:content_addressable_document, inserted_at: DateTime.add(DateTime.utc_now(), -91, :second))

      umbrella = insert(:umbrella_snapshot)
      kube = insert(:kube_snapshot, umbrella_snapshot_id: umbrella.id, status: :ok)

      # Create the Resource path so the document is referenced
      _ = insert(:resource_path, kube_snapshot_id: kube.id, document_id: document.id, hash: document.hash)
      assert Reap.reap_unused_documents() == 0
      # Now delete the umbrella snapshot
      assert {:ok, _} = Repo.delete(umbrella)
      # The document gets deleted
      assert Reap.reap_unused_documents() == 1
    end
  end
end
