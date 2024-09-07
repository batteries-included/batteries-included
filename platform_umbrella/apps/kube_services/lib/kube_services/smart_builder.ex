defmodule KubeServices.SmartBuilder do
  @moduledoc false
  alias CommonCore.FerretDB.FerretService
  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Ollama.ModelInstance
  alias CommonCore.Postgres.Cluster, as: PGCluster
  alias CommonCore.Postgres.PGDatabase
  alias CommonCore.Postgres.PGUser
  alias CommonCore.Redis.RedisInstance, as: RedisCluster
  alias CommonCore.TraditionalServices.Service, as: TraditionalService
  alias KubeServices.SystemState.SummaryBatteries

  def new_postgres do
    default_user_name = "root"
    default_permissions = ["login", "superuser"]

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
    %RedisCluster{
      num_instances: 1,
      virtual_size: Atom.to_string(SummaryBatteries.default_size())
    }
  end

  def new_ferretdb do
    %FerretService{
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

  def new_model_instance_params do
    %ModelInstance{virtual_size: Atom.to_string(SummaryBatteries.default_size())}
  end

  def new_traditional_service do
    %TraditionalService{
      virtual_size: Atom.to_string(SummaryBatteries.default_size())
    }
  end
end
