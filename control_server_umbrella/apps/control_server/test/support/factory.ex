defmodule ControlServer.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: ControlServer.Repo

  def raw_config_factory do
    %ControlServer.Configs.RawConfig{
      path: sequence("/config/path-"),
      content: %{}
    }
  end
end
