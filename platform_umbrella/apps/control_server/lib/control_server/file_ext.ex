defmodule ControlServer.FileExt do
  @moduledoc """
  Module to list file paths
  """

  def ls_r(path \\ ".") do
    cond do
      File.regular?(path) ->
        [path]

      File.dir?(path) ->
        path
        |> File.ls!()
        |> Enum.map(&Path.join(path, &1))
        |> Enum.map(&ls_r/1)
        |> Enum.concat()

      true ->
        []
    end
  end

  def read_secure(path) do
    :control_server
    |> Application.app_dir(["priv", "secure"])
    |> Path.join(path)
    |> File.read!()
  end

  def read_yaml(path, :prometheus),
    do: do_read_yaml(path, ["priv", "kube-prometheus", "manifests"])

  def read_yaml(path, :postgres),
    do: do_read_yaml(path, ["priv", "postgres-operator", "manifests"])

  def read_yaml(path, :exported),
    do: do_read_yaml(path, ["priv", "manifests"])

  defp do_read_yaml(path, repo_paths) do
    full_path = :control_server |> Application.app_dir(repo_paths) |> Path.join(path)

    with {:ok, yaml_content} <- YamlElixir.read_all_from_file(full_path) do
      yaml_content
    end
  end
end
