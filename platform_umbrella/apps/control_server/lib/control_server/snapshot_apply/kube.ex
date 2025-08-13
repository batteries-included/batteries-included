defmodule ControlServer.SnapshotApply.Kube do
  @moduledoc false

  use ControlServer, :context

  alias ControlServer.SnapshotApply.KubeSnapshot
  alias ControlServer.SnapshotApply.ResourcePath
  alias EventCenter.KubeSnapshot, as: SnapshotEventCenter

  @doc """
  Returns the list of resource_paths.

  ## Examples

      iex> list_resource_paths()
      [%ResourcePath{}, ...]

  """
  def list_resource_paths do
    Repo.all(ResourcePath)
  end

  @doc """
  Returns the list of kube_snapshots.

  ## Examples

      iex> list_kube_snapshots()
      [%KubeSnapshot{}, ...]

  """
  def list_kube_snapshots do
    Repo.all(KubeSnapshot)
  end

  def paginated_kube_snapshots(opts \\ %{}) do
    Repo.Flop.validate_and_run!(
      from(ks in KubeSnapshot),
      opts,
      for: KubeSnapshot
    )
  end

  def trim_kube_snapshots(keep_time) do
    Repo.delete_all(from ks in KubeSnapshot, where: ks.updated_at > ^keep_time)
  end

  @doc """
  Gets a single kube_snapshot.

  Raises `Ecto.NoResultsError` if the Kube snapshot does not exist.

  ## Examples

      iex> get_kube_snapshot!(123)
      %KubeSnapshot{}

      iex> get_kube_snapshot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_kube_snapshot!(id), do: Repo.get!(KubeSnapshot, id)

  @spec get_latest_snapshot_status() :: nil | :error | :ok
  def get_latest_snapshot_status do
    query =
      from ks in KubeSnapshot,
        order_by: [desc: ks.inserted_at, desc: ks.id],
        select: [:status],
        limit: 1

    snapshot = Repo.one(query)

    case snapshot do
      %KubeSnapshot{status: :ok} -> :ok
      %KubeSnapshot{status: :error} -> :error
      _ -> nil
    end
  end

  def get_preloaded_kube_snapshot!(id) do
    rp_query =
      from rp in ResourcePath,
        order_by: [rp.is_success, rp.path],
        select: [
          :apply_result,
          :hash,
          :id,
          :name,
          :namespace,
          :inserted_at,
          :is_success,
          :path,
          :updated_at
        ]

    query =
      from ks in KubeSnapshot,
        select: ks,
        where: ks.id == ^id,
        preload: [
          resource_paths: ^rp_query
        ]

    Repo.one!(query)
  end

  @doc """
  Creates a kube_snapshot.

  ## Examples

      iex> create_kube_snapshot(%{field: value})
      {:ok, %KubeSnapshot{}}

      iex> create_kube_snapshot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_kube_snapshot(attrs \\ %{}) do
    %KubeSnapshot{}
    |> KubeSnapshot.changeset(attrs)
    |> Repo.insert()
    |> broadcast_snap()
  end

  def snapshot_success(query \\ KubeSnapshot) do
    from ks in query, where: ks.status == :ok
  end

  def snapshot_recently(query \\ KubeSnapshot) do
    from ks in query,
      where: ks.inserted_at >= ^DateTime.add(DateTime.utc_now(), -1, :hour)
  end

  def resource_paths_outstanding(query \\ ResourcePath) do
    from rp in query, where: is_nil(rp.is_success)
  end

  def resource_paths_failed(query \\ ResourcePath) do
    from rp in query, where: rp.is_success == false
  end

  def resource_paths_success(query \\ ResourcePath) do
    from rp in query, where: rp.is_success == true
  end

  def resource_paths_by_type(query \\ ResourcePath, type) do
    from rp in query, where: rp.type == ^type
  end

  def resource_paths_by_name(query \\ ResourcePath, name) do
    from rp in query, where: rp.name == ^name
  end

  def resource_paths_by_namespace(query \\ ResourcePath, namespace), do: by_namespace(query, namespace)

  defp by_namespace(query, namespace) when is_nil(namespace) do
    from rp in query, where: is_nil(rp.namespace)
  end

  defp by_namespace(query, namespace) do
    from rp in query, where: rp.namespace == ^namespace
  end

  def resource_paths_recently(query \\ ResourcePath) do
    from rp in query,
      where: rp.inserted_at >= ^DateTime.add(DateTime.utc_now(), -1, :hour)
  end

  def count_paths(query \\ ResourcePath), do: Repo.one(from rp in query, select: fragment("count(*)"))

  @doc """
  Updates a kube_snapshot.

  ## Examples

      iex> update_kube_snapshot(kube_snapshot, %{field: new_value})
      {:ok, %KubeSnapshot{}}

      iex> update_kube_snapshot(kube_snapshot, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_kube_snapshot(%KubeSnapshot{} = kube_snapshot, attrs) do
    kube_snapshot
    |> KubeSnapshot.changeset(attrs)
    |> Repo.update()
    |> broadcast_snap()
  end

  @doc """
  Deletes a kube_snapshot.

  ## Examples

      iex> delete_kube_snapshot(kube_snapshot)
      {:ok, %KubeSnapshot{}}

      iex> delete_kube_snapshot(kube_snapshot)
      {:error, %Ecto.Changeset{}}

  """
  def delete_kube_snapshot(%KubeSnapshot{} = kube_snapshot) do
    kube_snapshot
    |> Repo.delete()
    |> broadcast_snap()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking kube_snapshot changes.

  ## Examples

      iex> change_kube_snapshot(kube_snapshot)
      %Ecto.Changeset{data: %KubeSnapshot{}}

  """
  def change_kube_snapshot(%KubeSnapshot{} = kube_snapshot, attrs \\ %{}) do
    KubeSnapshot.changeset(kube_snapshot, attrs)
  end

  @doc """
  Gets a single resource_path.

  Raises `Ecto.NoResultsError` if the Resource path does not exist.

  ## Examples

      iex> get_resource_path!(123)
      %ResourcePath{}

      iex> get_resource_path!(456)
      ** (Ecto.NoResultsError)

  """
  def get_resource_path!(id) do
    Repo.get!(ResourcePath, id)
  end

  @doc """
  Creates a resource_path.

  ## Examples

      iex> create_resource_path(%{field: value})
      {:ok, %ResourcePath{}}

      iex> create_resource_path(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_resource_path(attrs \\ %{}) do
    %ResourcePath{}
    |> ResourcePath.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a resource_path.

  ## Examples

      iex> update_resource_path(resource_path, %{field: new_value})
      {:ok, %ResourcePath{}}

      iex> update_resource_path(resource_path, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_resource_path(%ResourcePath{} = resource_path, attrs) do
    resource_path
    |> ResourcePath.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a resource_path.

  ## Examples

      iex> delete_resource_path(resource_path)
      {:ok, %ResourcePath{}}

      iex> delete_resource_path(resource_path)
      {:error, %Ecto.Changeset{}}

  """
  def delete_resource_path(%ResourcePath{} = resource_path) do
    Repo.delete(resource_path)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resource_path changes.

  ## Examples

      iex> change_resource_path(resource_path)
      %Ecto.Changeset{data: %ResourcePath{}}

  """
  def change_resource_path(%ResourcePath{} = resource_path, attrs \\ %{}) do
    ResourcePath.changeset(resource_path, attrs)
  end

  defp broadcast_snap({:ok, %KubeSnapshot{} = snap} = result) do
    :ok = SnapshotEventCenter.broadcast(snap)
    result
  end

  defp broadcast_snap(result), do: result
end
