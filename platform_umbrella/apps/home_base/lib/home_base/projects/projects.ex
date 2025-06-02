defmodule HomeBase.Projects do
  @moduledoc false
  import Ecto.Query, warn: false

  alias CommonCore.Accounts.User
  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.Installation
  alias CommonCore.Teams.Team
  alias HomeBase.Projects.StoredProjectSnapshot
  alias HomeBase.Repo

  def create_stored_project_snapshot(attrs \\ %{}) do
    %StoredProjectSnapshot{}
    |> StoredProjectSnapshot.changeset(attrs)
    |> Repo.insert()
  end

  def snapshots_for(%{} = owner) do
    owning_ids = owning_installations(owner)

    query =
      from s in StoredProjectSnapshot,
        where: s.installation_id in subquery(owning_ids) or s.visibility == :public,
        order_by: [desc: s.inserted_at],
        select: %{
          id: s.id,
          name: s.snapshot["name"],
          description: s.snapshot["description"],
          num_postgres_clusters: fragment("jsonb_array_length(?)", s.snapshot["postgres_clusters"]),
          num_redis_instances: fragment("jsonb_array_length(?)", s.snapshot["redis_instances"]),
          num_jupyter_notebooks: fragment("jsonb_array_length(?)", s.snapshot["jupyter_notebooks"]),
          num_knative_services: fragment("jsonb_array_length(?)", s.snapshot["knative_services"]),
          num_traditional_services: fragment("jsonb_array_length(?)", s.snapshot["traditional_services"]),
          num_model_instances: fragment("jsonb_array_length(?)", s.snapshot["model_instances"])
        }

    Repo.all(query)
  end

  def get_stored_project_snapshot(%Installation{} = installation, id) do
    owning_ids = owning_installations(installation)

    query =
      from s in StoredProjectSnapshot,
        # This where clause is to ensure that this installation key's has access to the snapshot
        where: s.installation_id in subquery(owning_ids) or is_nil(s.installation_id),
        where: s.id == ^id,
        select: s

    Repo.one(query)
  end

  # This should only be used for internal purposes, since it doesn't check ownership
  # of the snapshot. Use with caution.
  def get_stored_project_snapshot!(id) do
    Repo.get!(StoredProjectSnapshot, id)
  end

  defp owning_installations(%Installation{team_id: nil, user_id: nil, id: id} = _installation) do
    values = [%{id: id}]
    types = %{id: BatteryUUID}

    from v in values(values, types),
      select: v.id
  end

  defp owning_installations(%Installation{team_id: nil, user_id: user_id} = installation) when user_id != nil do
    from i in Installation,
      where: i.user_id == ^user_id or i.id == ^installation.id,
      select: i.id
  end

  defp owning_installations(%Installation{team_id: team_id, user_id: nil} = installation) when team_id != nil do
    from i in Installation,
      where: i.team_id == ^team_id or i.id == ^installation.id,
      select: i.id
  end

  defp owning_installations(%Installation{team_id: team_id, user_id: user_id} = installation)
       when team_id != nil and user_id != nil do
    from i in Installation,
      where: i.user_id == ^user_id or i.team_id == ^team_id or i.id == ^installation.id,
      select: i.id
  end

  defp owning_installations(%Team{} = team) do
    from i in Installation,
      where: i.team_id == ^team.id,
      select: i.id
  end

  defp owning_installations(%User{} = user) do
    from i in Installation,
      where: i.user_id == ^user.id,
      select: i.id
  end
end
