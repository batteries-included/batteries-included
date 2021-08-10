defmodule ControlServer.Services.Network do
  alias ControlServer.Services

  @default_path "/network"
  @default_config %{}

  def default_config, do: @default_config

  def activate!(path \\ @default_path) do
    Services.create_base_service!(%{
      is_active: true,
      root_path: path,
      service_type: :network,
      config: @default_config
    })
  end

  def active?(path \\ @default_path), do: Services.active?(path)
end
