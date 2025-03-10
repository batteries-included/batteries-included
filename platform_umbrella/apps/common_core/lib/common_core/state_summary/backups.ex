defmodule CommonCore.StateSummary.Backups do
  @moduledoc false
  import CommonCore.Util.String

  alias CommonCore.StateSummary

  @doc """
  Retrieve CNPG backups from a state summary. Optionally filter by cluster name.
  """
  @spec backups(StateSummary.t(), String.t() | nil) :: list(map())
  def backups(summary, cluster \\ nil)

  def backups(%StateSummary{kube_state: kube_state} = _summary, _cluster)
      when not is_map_key(kube_state, :cloudnative_pg_backup),
      do: []

  def backups(%StateSummary{kube_state: %{cloudnative_pg_backup: backups}} = _summary, cluster) when is_empty(cluster),
    do: backups

  def backups(%StateSummary{kube_state: %{cloudnative_pg_backup: backups}} = _summary, cluster) do
    # allow passing either the full cluster name e.g. pg-controlserver or just the suffix e.g. controlserver
    names = [cluster, "pg-#{cluster}"]
    Enum.filter(backups, &(get_in(&1, ["spec", "cluster", "name"]) in names))
  end
end
