defmodule ControlServer.Services.Security do
  @moduledoc """
  Module for dealing with all the security related services
  """
  alias ControlServer.Services

  @default_path "/security/base"
  @default_config %{}

  def default_config, do: @default_config

  def activate!(path \\ @default_path) do
    Services.find_or_create!(%{
      is_active: true,
      root_path: path,
      service_type: :security,
      config: @default_config
    })
  end

  def active?(path \\ @default_path), do: Services.active?(path)
end
