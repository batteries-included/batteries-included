defmodule KubeExt.SystemState.StateSummary do
  @derive Jason.Encoder
  defstruct batteries: [],
            postgres_clusters: [],
            redis_clusters: [],
            notebooks: [],
            knative_services: [],
            ceph_clusters: [],
            ceph_filesystems: [],
            kube_state: %{}

  @type t :: %__MODULE__{
          batteries: list(),
          postgres_clusters: list(),
          redis_clusters: list(),
          notebooks: list(),
          knative_services: list(),
          ceph_clusters: list(),
          ceph_filesystems: list(),
          kube_state: map()
        }
end
