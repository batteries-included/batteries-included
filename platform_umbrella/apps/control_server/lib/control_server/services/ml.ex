defmodule ControlServer.Services.ML do
  alias ControlServer.Services
  alias ControlServer.Services.Network

  @default_path "/ml/base"
  @default_config %{}

  def default_config, do: @default_config

  def activate!(path \\ @default_path) do
    Network.activate!()

    Services.find_or_create!(%{
      is_active: true,
      root_path: path,
      service_type: :ml,
      config: @default_config
    })
  end

  def active?(path \\ @default_path), do: Services.active?(path)
end
