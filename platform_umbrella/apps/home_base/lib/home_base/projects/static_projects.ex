defmodule HomeBase.Projects.StaticProjects do
  @moduledoc false
  use CommonCore.IncludeResource,
    rag_v0: "priv/stored_projects/batt_0197313f7c447c85ab2462d284f01077.json"

  def static_projects(install_id \\ nil) do
    Map.new([{"batt_0197313f7c447c85ab2462d284f01077", :rag_v0}], fn {id, resource} ->
      {id, to_stored(id, to_snapshot(resource, install_id))}
    end)
  end

  defp to_stored(id, snapshot) do
    HomeBase.Projects.StoredProjectSnapshot.new!(
      id: id,
      snapshot: snapshot,
      installation_id: nil,
      visibility: :public
    )
  end

  defp to_snapshot(resource, install_id) do
    resource
    |> get_resource()
    |> Jason.decode!()
    |> Map.put("installation_id", install_id)
    |> CommonCore.Projects.ProjectSnapshot.new!()
  end
end
