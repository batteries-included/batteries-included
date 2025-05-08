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

  def snapshots_for(%{} = installation) do
    owning_ids = owning_installations(installation)

    query =
      from s in StoredProjectSnapshot,
        where: s.installation_id in subquery(owning_ids),
        select: s

    query
    |> Repo.all()
    |> Enum.map(& &1.snapshot)
  end

  defp owning_installations(%Installation{team_id: nil, user_id: nil, id: id} = _installation) do
    values = [%{id: id}]
    types = %{id: BatteryUUID}

    from v in values(values, types),
      select: v.id
  end

  defp owning_installations(%Installation{team_id: nil, user_id: user_id} = _installation) when user_id != nil do
    from i in Installation,
      where: i.user_id == ^user_id,
      select: i.id
  end

  defp owning_installations(%Installation{team_id: team_id, user_id: nil} = _installation) when team_id != nil do
    from i in Installation,
      where: i.team_id == ^team_id,
      select: i.id
  end

  defp owning_installations(%Installation{team_id: team_id, user_id: user_id} = _installation)
       when team_id != nil and user_id != nil do
    from i in Installation,
      where: i.user_id == ^user_id or i.team_id == ^team_id,
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
