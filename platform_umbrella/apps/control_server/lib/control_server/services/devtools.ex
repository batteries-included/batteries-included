defmodule ControlServer.Services.Devtools do
  @moduledoc """
  Module for dealing with all the Devtools related services
  """

  alias ControlServer.Services
  alias ControlServer.Services.Security

  @default_path "/Devtools/base"
  @default_config %{}

  def default_config, do: @default_config

  def activate!(path \\ @default_path) do
    Security.activate!()

    Services.create_base_service!(%{
      is_active: true,
      root_path: path,
      service_type: :devtools,
      config: @default_config
    })
  end

  def active?(path \\ @default_path), do: Services.active?(path)
end
