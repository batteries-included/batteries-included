defmodule ControlServer.Services.RunnableService do
  alias ControlServer.Postgres
  alias ControlServer.Redis
  alias ControlServer.Repo
  alias ControlServer.Services
  alias Ecto.Multi

  require Logger

  @enforce_keys [:service_type, :path]
  defstruct service_type: nil,
            path: nil,
            config: %{},
            dependencies: [],
            config_gen: nil,
            post: nil

  def services,
    do: [
      # Data
      %__MODULE__{path: "/data/common", service_type: :data, dependencies: [:battery]},
      %__MODULE__{path: "/data/redis", service_type: :redis, dependencies: [:data, :battery]},
      %__MODULE__{
        path: "/data/postgres/operator",
        service_type: :postgres_operator,
        dependencies: [:data, :battery]
      },
      %__MODULE__{
        path: "/data/postgres/public",
        service_type: :database_public,
        dependencies: [:postgres_operator, :data, :battery]
      },
      %__MODULE__{
        path: "/data/postgres/internal",
        service_type: :database_internal,
        dependencies: [:postgres_operator, :data],
        post: fn repo ->
          Postgres.find_or_create(KubeRawResources.Battery.control_cluster(), repo)
        end
      },
      %__MODULE__{
        path: "/data/rook",
        service_type: :rook,
        dependencies: [:data]
      },
      # Battery
      %__MODULE__{path: "/battery/core", service_type: :battery},
      %__MODULE__{
        path: "/battery/control_server",
        service_type: :control_server,
        dependencies: [:battery, :istio_gateway]
      },
      %__MODULE__{
        path: "/battery/echo",
        service_type: :echo_server,
        dependencies: [:battery, :istio_gateway]
      },

      # Devtools
      %__MODULE__{
        path: "/devtools/knative/operator",
        service_type: :knative,
        dependencies: [:battery]
      },
      %__MODULE__{
        path: "/devtools/knative/serving",
        service_type: :knative_serving,
        dependencies: [:knative, :istio_gateway]
      },
      %__MODULE__{
        path: "/devtools/gitea",
        service_type: :gitea,
        dependencies: [:keycloak, :database_internal, :istio_gateway, :battery],
        post: fn repo ->
          Postgres.find_or_create(KubeRawResources.Gitea.gitea_cluster(), repo)
        end
      },
      %__MODULE__{
        path: "/devtools/tekton",
        service_type: :tekton,
        dependencies: [:battery]
      },
      %__MODULE__{
        path: "/devtools/tekton_dashboard",
        service_type: :tekton_dashboard,
        dependencies: [:battery, :tekton, :istio_gateway]
      },
      %__MODULE__{
        path: "/devtools/harbor",
        service_type: :harbor,
        dependencies: [:battery, :redis, :istio_gateway, :database_internal],
        post: fn repo ->
          with {:ok, postgres_db} <-
                 Postgres.find_or_create(KubeRawResources.Harbor.harbor_pg_cluster(), repo),
               {:ok, redis} <-
                 Redis.create_failover_cluster(
                   KubeRawResources.Harbor.harbor_redis_cluster(),
                   repo
                 ) do
            {:ok, postgres: postgres_db, redis: redis}
          end
        end
      },
      # ML
      %__MODULE__{path: "/ml/core", service_type: :ml},
      %__MODULE__{
        path: "/ml/notebooks",
        service_type: :notebooks,
        dependencies: [:ml, :istio_gateway]
      },

      # Monitoring
      %__MODULE__{
        path: "/monitoring/prometheus_operator",
        service_type: :prometheus_operator,
        dependencies: [:battery]
      },
      %__MODULE__{
        path: "/monitoring/grafana",
        service_type: :grafana,
        dependencies: [:prometheus_operator, :istio_gateway]
      },
      %__MODULE__{
        path: "/monitoring/alert_manager",
        service_type: :alert_manager,
        dependencies: [:prometheus_operator, :istio_gateway]
      },
      %__MODULE__{
        path: "/monitoring/prometheus",
        service_type: :prometheus,
        dependencies: [:prometheus_operator, :istio_gateway]
      },
      %__MODULE__{
        path: "/monitoring/kube_state_metrics",
        service_type: :kube_state_metrics,
        dependencies: [:prometheus]
      },
      %__MODULE__{
        path: "/monitoring/node_exporter",
        service_type: :node_exporter,
        dependencies: [:prometheus]
      },
      %__MODULE__{
        path: "/monitoring/api_server",
        service_type: :monitoring_api_server,
        dependencies: [:prometheus, :grafana]
      },
      %__MODULE__{
        path: "/monitoring/controller_manager",
        service_type: :monitoring_controller_manager,
        dependencies: [:prometheus, :grafana]
      },
      %__MODULE__{
        path: "/monitoring/coredns",
        service_type: :monitoring_coredns,
        dependencies: [:prometheus, :grafana]
      },
      %__MODULE__{
        path: "/monitoring/etcd",
        service_type: :monitoring_etcd,
        dependencies: [:prometheus, :grafana]
      },
      %__MODULE__{
        path: "/monitoring/kube_proxy",
        service_type: :monitoring_kube_proxy,
        dependencies: [:prometheus, :grafana]
      },
      %__MODULE__{
        path: "/monitoring/kubelet",
        service_type: :monitoring_kubelet,
        dependencies: [:prometheus, :grafana]
      },
      %__MODULE__{
        path: "/monitoring/scheduler",
        service_type: :monitoring_scheduler,
        dependencies: [:prometheus, :grafana]
      },
      %__MODULE__{
        path: "/monitoring/prometheus_stack",
        service_type: :prometheus_stack,
        dependencies: [
          :battery,
          :prometheus_operator,
          :grafana,
          :alert_manager,
          :prometheus,
          :node_exporter,
          :kube_state_metrics,
          :monitoring_api_server,
          :monitoring_controller_manager,
          :monitoring_coredns,
          :monitoring_etcd,
          :monitoring_kube_proxy,
          :monitoring_kubelet,
          :monitoring_scheduler
        ]
      },
      %__MODULE__{
        path: "/monitoring/loki",
        service_type: :loki,
        dependencies: [:battery, :prometheus, :grafana, :istio_gateway]
      },
      %__MODULE__{
        path: "/monitoring/promtail",
        service_type: :promtail,
        dependencies: [:loki]
      },
      # Network
      %__MODULE__{path: "/network/istio/base", service_type: :istio, dependencies: [:battery]},
      %__MODULE__{
        path: "/network/istio/istiod",
        service_type: :istio_istiod,
        dependencies: [:istio, :battery]
      },
      %__MODULE__{
        path: "/network/istio/gateway",
        service_type: :istio_gateway,
        dependencies: [:istio_istiod, :istio]
      },
      %__MODULE__{
        path: "/network/kiali",
        service_type: :kiali,
        dependencies: [:istio_istiod, :istio_gateway, :prometheus, :grafana]
      },
      %__MODULE__{
        path: "/network/metallb",
        service_type: :metallb,
        dependencies: [:istio_istiod, :istio_gateway]
      },
      %__MODULE__{
        path: "/network/dev_metallb",
        service_type: :dev_metallb,
        dependencies: [:metallb]
      },
      # Security
      %__MODULE__{
        path: "/security/cert_manager",
        service_type: :cert_manager,
        dependencies: [:battery]
      },
      %__MODULE__{
        path: "/security/keycloak",
        service_type: :keycloak,
        dependencies: [:database_internal, :istio_gateway],
        post: fn repo ->
          Postgres.find_or_create(KubeRawResources.Keycloak.keycloak_cluster(), repo)
        end
      },
      %__MODULE__{
        path: "/security/ory_hydra",
        service_type: :ory_hydra,
        dependencies: [:database_internal],
        post: fn repo ->
          Postgres.find_or_create(KubeRawResources.OryHydra.hydra_cluster(), repo)
        end
      }
    ]

  def services_map, do: services() |> Enum.map(fn s -> {s.service_type, s} end) |> Enum.into(%{})

  def prefix(prefix) do
    Enum.filter(services(), fn s -> String.starts_with?(s.path, prefix) end)
  end

  def activate!(service_type) when is_binary(service_type) do
    Logger.debug("activating string #{service_type}")

    service_type
    |> String.to_atom()
    |> activate!()
  end

  def activate!(service_type) when is_atom(service_type) do
    Logger.debug("activating #{service_type}")
    runnable = Map.get(services_map(), service_type)

    Logger.debug("Runnable -> #{inspect(runnable)}")
    services_map() |> Map.get(service_type) |> activate!()
  end

  def activate!(%__MODULE__{
        path: path,
        service_type: service_type,
        config: config,
        config_gen: config_gen,
        post: post,
        dependencies: deps
      }) do
    Multi.new()
    |> Multi.run(:dependencies, fn _repo, _state ->
      Enum.each(deps, fn s -> activate!(s) end)
      {:ok, deps}
    end)
    |> Multi.merge(fn _ ->
      final_config = maybe_gen_config(config, config_gen)

      Services.find_or_create_multi(%{
        root_path: path,
        service_type: service_type,
        config: final_config
      })
    end)
    |> Multi.run(:post, fn repo, %{selected: existing} = _state ->
      maybe_run_post(existing, post, repo)
    end)
    |> Repo.transaction()
  end

  def active?(path) when is_bitstring(path), do: Services.active?(path)

  def active?(service_type) when is_atom(service_type),
    do: services_map() |> Map.get(service_type) |> active?()

  def active?(%__MODULE__{path: path} = _service), do: Services.active?(path)

  # If this service wasn't selected, but there's no post method
  # just bail out
  def maybe_run_post(nil, nil = _post, _repo), do: {:ok, []}
  # If there was no service selected and there is a post method
  # then call that method
  def maybe_run_post(nil, post, repo), do: post.(repo)
  # If there's something other than nil that was selected
  # then just bail out.
  def maybe_run_post(_it_existed, _service, _repo), do: {:ok, []}

  def maybe_gen_config(config, nil = _gen_config), do: config
  def maybe_gen_config(config, config_gen), do: config_gen.(config)
end
