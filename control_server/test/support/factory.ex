defmodule Server.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: Server.Repo

  def raw_config_factory do
    %Server.Configs.RawConfig{
      path: sequence("/config/path-"),
      content: %{}
    }
  end
end
