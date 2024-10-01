defmodule ControlServer.Timeline do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.Timeline.BatteryInstall
  alias CommonCore.Timeline.Keycloak
  alias CommonCore.Timeline.Kube
  alias CommonCore.Timeline.NamedDatabase
  alias CommonCore.Timeline.TimelineEvent
  alias EventCenter.Database, as: DatabaseEventCenter

  @doc """
  Returns the list of timeline_events.

  ## Examples

      iex> list_timeline_events()
      [%TimelineEvent{}, ...]

  """
  def list_timeline_events(limit \\ 20) do
    Repo.all(from TimelineEvent, order_by: [desc: :updated_at], limit: ^limit)
  end

  @doc """
  Gets a single timeline_event.

  Raises `Ecto.NoResultsError` if the Timeline event does not exist.

  ## Examples

      iex> get_timeline_event!(123)
      %TimelineEvent{}

      iex> get_timeline_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_timeline_event!(id), do: Repo.get!(TimelineEvent, id)

  @doc """
  Creates a timeline_event.

  ## Examples

      iex> create_timeline_event(%{field: value})
      {:ok, %TimelineEvent{}}

      iex> create_timeline_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_timeline_event(a \\ %{}, repo \\ Repo), do: do_create_timeline_event(a, repo)

  defp do_create_timeline_event(%TimelineEvent{} = timeline_event, repo) do
    timeline_event
    |> TimelineEvent.changeset(%{})
    |> repo.insert()
    |> broadcast(:insert)
  end

  defp do_create_timeline_event(attrs, repo) do
    %TimelineEvent{}
    |> TimelineEvent.changeset(attrs)
    |> repo.insert()
    |> broadcast(:insert)
  end

  def battery_install_event(type) do
    %TimelineEvent{
      type: :battery_install,
      payload: %BatteryInstall{battery_type: type}
    }
  end

  def kube_event(action, resource_type, name, namespace \\ nil, status \\ nil) do
    %TimelineEvent{
      type: :kube,
      payload: %Kube{
        action: action,
        resource_type: resource_type,
        name: name,
        namespace: namespace,
        computed_status: status
      }
    }
  end

  def named_database_event(action, type, name, entity_id) do
    %TimelineEvent{
      type: :named_database,
      payload: %NamedDatabase{
        name: name,
        action: action,
        schema_type: type,
        entity_id: entity_id
      }
    }
  end

  def keycloak_event(action, entity_id, realm) do
    %TimelineEvent{
      type: :keycloak,
      payload: %Keycloak{
        action: action,
        entity_id: entity_id,
        realm: realm
      }
    }
  end

  @doc """
  Updates a timeline_event.

  ## Examples

      iex> update_timeline_event(timeline_event, %{field: new_value})
      {:ok, %TimelineEvent{}}

      iex> update_timeline_event(timeline_event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_timeline_event(%TimelineEvent{} = timeline_event, attrs) do
    timeline_event
    |> TimelineEvent.changeset(attrs)
    |> Repo.update()
    |> broadcast(:update)
  end

  @doc """
  Deletes a timeline_event.

  ## Examples

      iex> delete_timeline_event(timeline_event)
      {:ok, %TimelineEvent{}}

      iex> delete_timeline_event(timeline_event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_timeline_event(%TimelineEvent{} = timeline_event) do
    timeline_event
    |> Repo.delete()
    |> broadcast(:update)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking timeline_event changes.

  ## Examples

      iex> change_timeline_event(timeline_event)
      %Ecto.Changeset{data: %TimelineEvent{}}

  """
  def change_timeline_event(%TimelineEvent{} = timeline_event, attrs \\ %{}) do
    TimelineEvent.changeset(timeline_event, attrs)
  end

  defp broadcast({:ok, fc} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:timeline_event, action, fc)
    result
  end

  defp broadcast(result, _action), do: result
end
