defmodule ControlServer.ContentAddressableResources do
  import Ecto.Query, warn: false
  alias ControlServer.Repo

  alias ControlServer.SnapshotApply.ContentAddressableResource

  def list_content_addressable_resources do
    Repo.all(ContentAddressableResource)
  end
end
