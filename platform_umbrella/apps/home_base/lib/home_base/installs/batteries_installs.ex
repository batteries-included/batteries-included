defmodule HomeBase.BatteriesInstalls do
  @moduledoc false
  use HomeBase, :context

  alias CommonCore.Installation

  def list_internal_prod_installations do
    from(i in Installation)
    |> where_usage(:internal_prod)
    |> where_team(CommonCore.Accounts.AdminTeams.admin_team_ids())
    |> Repo.all()
  end

  defp where_usage(query, usage) do
    from(i in query,
      where: i.usage == ^usage
    )
  end

  defp where_team(query, team_ids) do
    from(i in query,
      where: i.team_id in ^team_ids
    )
  end
end
