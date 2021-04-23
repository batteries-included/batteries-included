defmodule ControlServer.Factory do
  @moduledoc """

  Factory for control_server ecto.
  """

  # with Ecto
  use ExMachina.Ecto, repo: ControlServer.Repo

  def base_service_factory do
    %ControlServer.Services.BaseService{
      root_path: sequence(:root_path, &"/prometheus-#{&1}"),
      is_active: true,
      service_type: sequence(:service_type, [:prometheus, :postgres])
    }
  end
end
