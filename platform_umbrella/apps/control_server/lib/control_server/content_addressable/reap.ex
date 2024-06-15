defmodule ControlServer.ContentAddressable.Reap do
  @moduledoc false

  import Ecto.Query

  alias ControlServer.ContentAddressable.Document
  alias ControlServer.Deleted.DeletedResource
  alias ControlServer.Repo
  alias ControlServer.SnapshotApply.KeycloakAction
  alias ControlServer.SnapshotApply.ResourcePath

  def reap_unused_documents do
    rp_id_subquery =
      from rp in ResourcePath,
        select: rp.document_id

    key_action_id_subquery =
      from ka in KeycloakAction,
        select: ka.document_id

    deleted_id_subquery =
      from dr in DeletedResource,
        select: dr.document_id

    # Don't delete really recent documents
    # JuUUUUUUUuuust in case there's some race somewhere
    #
    # Be a good neighbor and use transactions.
    safe_delete_time = DateTime.add(DateTime.utc_now(), -90, :second)

    query =
      from d in Document,
        where:
          d.id not in subquery(rp_id_subquery) and
            d.id not in subquery(key_action_id_subquery) and
            d.id not in subquery(deleted_id_subquery) and
            d.inserted_at < ^safe_delete_time

    {count, _} = Repo.delete_all(query)
    count
  end
end
