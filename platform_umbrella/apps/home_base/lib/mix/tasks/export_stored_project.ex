defmodule Mix.Tasks.HomeBase.ExportStoredProject do
  @moduledoc """
  Mix task that takes in an ID of a stored project snapshot
  pulls that from the database and then writes it to a yaml
  file for use in IncludedResources.
  """
  use Mix.Task

  @start_apps [:postgrex, :ecto, :ecto_sql, :home_base]
  @shutdown_abnormal {:shutdown, 1}
  @shutdown_normal {:shutdown, 0}

  # Run is always going to exit.
  # That's expected
  @dialyzer {:nowarn_function, run: 1}

  def run(args) do
    case args do
      [id] ->
        export_project(id)
        exit(@shutdown_normal)

      _ ->
        Mix.raise("Expected one argument: the project ID")
        exit(@shutdown_abnormal)
    end
  end

  defp export_project(id) do
    {:ok, _} = Application.ensure_all_started(@start_apps)
    stored_project = HomeBase.Projects.get_stored_project_snapshot!(id)
    write_snapshot_to_file!(stored_project)
  end

  defp ensure_priv_directory do
    parent = Application.app_dir(:home_base, "priv/stored_projects")
    File.mkdir_p!(parent)
  end

  defp write_snapshot_to_file!(stored_project) do
    path = Application.app_dir(:home_base, "priv/stored_projects/#{stored_project.id}.json")
    ensure_priv_directory()
    File.write!(path, Jason.encode!(stored_project.snapshot, pretty: true))
  end
end
