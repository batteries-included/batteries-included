defmodule ControlServer.FileExt do
  @moduledoc """
  Module to list file paths
  """

  def ls_r(path \\ ".") do
    cond do
      File.regular?(path) ->
        [path]

      File.dir?(path) ->
        File.ls!(path)
        |> Enum.map(&Path.join(path, &1))
        |> Enum.map(&ls_r/1)
        |> Enum.concat()

      true ->
        []
    end
  end

  def read_yaml(path, :prometheus),
    do: do_read_yaml(path, ["priv", "kube-prometheus", "manifests"])

  def read_yaml(path, :postgres),
    do: do_read_yaml(path, ["priv", "postgres-operator", "manifests"])

  defp do_read_yaml(path, repo_paths) do
    base_path = Application.app_dir(:control_server, repo_paths)

    with {:ok, yaml_content} <- YamlElixir.read_from_file(base_path <> "/" <> path) do
      yaml_content
    end
  end
end
