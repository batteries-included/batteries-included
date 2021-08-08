defmodule ControlServer.Services.Monitoring do
  @moduledoc """

  This is the entry way into our monitoing system. This will
  be in charge of the db side and generate all the needed
  k8s configs.
  """
  alias ControlServer.Services

  @default_path "/monitoring/base"
  @default_config %{}

  def default_config, do: @default_config

  def activate!(path \\ @default_path) do
    Services.create_base_service!(%{
      is_active: true,
      root_path: path,
      service_type: :monitoring,
      config: @default_config
    })
  end

  def active?(path \\ @default_path), do: Services.active?(path)
end
