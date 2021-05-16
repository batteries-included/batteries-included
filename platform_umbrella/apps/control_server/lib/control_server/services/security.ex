defmodule ControlServer.Services.Security do
  @moduledoc """
  Module for dealing with all the security related services
  """

  alias ControlServer.Services
  alias ControlServer.Services.CertManager
  alias ControlServer.Settings.SecuritySettings

  import ControlServer.FileExt

  @default_path "/security/base"
  @default_config %{}

  def default_config, do: @default_config

  def activate(path \\ @default_path),
    do: Services.update_active!(true, path, :security, @default_config)

  def deactivate(path \\ @default_path),
    do: Services.update_active!(false, path, :security, @default_config)

  def active?(path \\ @default_path), do: Services.active?(path)

  def materialize(%{} = config) do
    static = %{
      "/0/crd" => read_yaml("cert_manager-crds.yaml", :exported),
      "/0/namespace" => namespace(config)
    }

    body =
      CertManager.materialize(config)
      |> Enum.map(fn {key, value} -> {"/1/body" <> key, value} end)
      |> Map.new()

    %{} |> Map.merge(static) |> Map.merge(body)
  end

  defp namespace(config) do
    ns = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Namespace",
      "metadata" => %{
        "name" => ns
      }
    }
  end
end
