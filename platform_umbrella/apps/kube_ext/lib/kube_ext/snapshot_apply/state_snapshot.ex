defmodule KubeExt.SnapshotApply.StateSnapshot do
  defstruct system_batteries: [],
            postgres_clusters: [],
            redis_clusters: [],
            notebooks: [],
            ceph_clusters: [],
            ceph_filesystems: [],
            kube_state: %{}
end
