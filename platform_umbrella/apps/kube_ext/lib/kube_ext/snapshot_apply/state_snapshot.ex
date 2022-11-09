defmodule KubeExt.SnapshotApply.StateSnapshot do
  @derive Jason.Encoder
  defstruct system_batteries: [],
            postgres_clusters: [],
            redis_clusters: [],
            notebooks: [],
            ceph_clusters: [],
            ceph_filesystems: [],
            kube_state: %{}

  @type t :: %__MODULE__{
          system_batteries: list(),
          postgres_clusters: list(),
          redis_clusters: list(),
          notebooks: list(),
          ceph_clusters: list(),
          ceph_filesystems: list(),
          kube_state: map()
        }
end
