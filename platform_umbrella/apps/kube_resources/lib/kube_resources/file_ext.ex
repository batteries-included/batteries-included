defmodule KubeResources.FileExt do
  @moduledoc """
  Module to list file paths
  """

  def read_yaml(path, :base),
    do: do_read_yaml(path, ["priv", "manifests"])

  defp do_read_yaml(path, repo_paths) do
    full_path = :control_server |> Application.app_dir(repo_paths) |> Path.join(path)

    with {:ok, yaml_content} <- YamlElixir.read_all_from_file(full_path) do
      yaml_content
    end
  end
end
