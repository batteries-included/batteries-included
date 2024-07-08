defmodule KubeServices.SmartBuilder do
  @moduledoc false
  alias CommonCore.Backend.Service, as: BackendService
  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Postgres.Cluster, as: PGCluster
  alias CommonCore.Postgres.PGDatabase
  alias CommonCore.Postgres.PGUser
  alias CommonCore.Redis.FailoverCluster, as: RedisCluster
  alias KubeServices.SystemState.SummaryBatteries

  def new_postgres do
    default_user_name = "app"
    default_permissions = ["login", "createdb", "createrole"]

    %PGCluster{
      virtual_size: Atom.to_string(SummaryBatteries.default_size()),
      database: %PGDatabase{name: "app", owner: default_user_name},
      users: [
        %PGUser{
          username: default_user_name,
          roles: default_permissions,
          credential_namespaces: [SummaryBatteries.core_namespace()]
        }
      ]
    }
  end

  def new_redis do
    # Anything but tiny will default to 1 sentinel instance
    num_sentinel_instances =
      if SummaryBatteries.default_size() == :tiny do
        0
      else
        1
      end

    %RedisCluster{
      num_redis_instances: 1,
      num_sentinel_instances: num_sentinel_instances,
      virtual_size: Atom.to_string(SummaryBatteries.default_size())
    }
  end

  def new_jupyter do
    %JupyterLabNotebook{
      virtual_size: Atom.to_string(SummaryBatteries.default_size())
    }
  end

  def new_juptyer_params do
    %{virtual_size: Atom.to_string(SummaryBatteries.default_size())}
  end

  def new_backend_service do
    %BackendService{
      virtual_size: Atom.to_string(SummaryBatteries.default_size())
    }
  end
end
