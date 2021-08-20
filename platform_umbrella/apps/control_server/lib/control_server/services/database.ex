defmodule ControlServer.Services.Database do
  @moduledoc """
  Module for dealing with all the databases for batteries included.
  """

  alias ControlServer.Services

  @default_path "/database/base"
  @default_config %{}

  def default_config, do: @default_config

  def activate!(path \\ @default_path) do
    Services.find_or_create!(%{
      is_active: true,
      root_path: path,
      service_type: :database,
      config: @default_config
    })
  end

  def active?(path \\ @default_path), do: Services.active?(path)
end
