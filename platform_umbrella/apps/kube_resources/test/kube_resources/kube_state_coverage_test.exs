defmodule KubeServices.KubeStateCoverageTest do
  use ExUnit.Case

  import K8s.Resource.FieldAccessors

  alias KubeResources.ConfigGenerator
  alias KubeExt.ApiVersionKind

  # We open up a watcher for each type.
  # Some types aren't worth the http connections
  @ignored_crd_types [
    # Ceph has too many types that we don't care about.
    {"objectbucket.io/v1alpha1", "ObjectBucketClaim"},
    {"objectbucket.io/v1alpha1", "ObjectBucket"},
    {"ceph.rook.io/v1", "CephFilesystemSubVolumeGroup"},
    {"ceph.rook.io/v1", "CephBlockPoolRadosNamespace"},
    {"ceph.rook.io/v1", "CephObjectZoneGroup"},
    {"ceph.rook.io/v1", "CephBucketTopic"},
    {"ceph.rook.io/v1", "CephBucketNotification"},
    {"ceph.rook.io/v1", "CephRBDMirror"},
    {"ceph.rook.io/v1", "CephFilesystemMirror"},
    {"ceph.rook.io/v1", "CephObjectStore"},
    {"ceph.rook.io/v1", "CephObjectRealm"},
    {"ceph.rook.io/v1", "CephObjectZone"},
    {"ceph.rook.io/v1", "CephObjectStoreUser"},
    {"ceph.rook.io/v1", "CephBlockPool"},
    {"ceph.rook.io/v1", "CephClient"},
    {"ceph.rook.io/v1", "CephNFS"},

    # Gotta look into why this is here
    {"install.istio.io/v1alpha1", "IstioOperator"},
    # No use for this
    {"monitoring.coreos.com/v1", "ThanosRuler"},

    # BGP will come later
    {"metallb.io/v1beta1", "BGPAdvertisement"},
    {"metallb.io/v1beta2", "BGPPeer"},
    {"metallb.io/v1beta1", "Community"},
    {"metallb.io/v1beta1", "BFDProfile"},

    # Istio has EVERYTHING
    {"networking.istio.io/v1beta1", "WorkloadGroup"},
    {"networking.istio.io/v1beta1", "WorkloadEntry"},
    {"networking.istio.io/v1beta1", "ServiceEntry"},
    {"networking.istio.io/v1beta1", "DestinationRule"},
    {"networking.istio.io/v1beta1", "Sidecar"},
    {"networking.istio.io/v1beta1", "ProxyConfig"}
  ]

  describe "KubeState can watch for every battery" do
    test "All watchable" do
      KubeExt.SystemState.SeedState.seed(:everything)
      |> ConfigGenerator.materialize()
      |> Enum.map(fn {_path, resource} -> {api_version(resource), kind(resource)} end)
      |> Enum.each(fn {api_version, kind} ->
        assert ApiVersionKind.is_watchable(api_version, kind),
               "Expected #{api_version} and #{kind} to be know types that can be watched by KubeState"
      end)
    end

    defp extract_crd_ver_kind(crd) do
      kind = get_in(crd, ~w|spec names kind|)
      group = get_in(crd, ~w|spec group|)

      version =
        crd
        |> get_in([Access.key("spec", %{}), Access.key("versions", [])])
        |> Enum.map(fn v -> Map.get(v, "name") end)
        |> Enum.sort()
        |> List.last(nil)

      api_version = "#{group}/#{version}"
      {api_version, kind}
    end

    test "All CRD's watchable" do
      KubeExt.SystemState.SeedState.seed(:everything)
      |> ConfigGenerator.materialize()
      |> Enum.filter(fn {_path, resource} -> ApiVersionKind.resource_type!(resource) == :crd end)
      |> Enum.map(fn {_path, crd} ->
        extract_crd_ver_kind(crd)
      end)
      |> Enum.reject(fn v -> Enum.member?(@ignored_crd_types, v) end)
      |> Enum.sort()
      |> Enum.uniq()
      |> Enum.each(fn {api_ver, res_kind} ->
        assert ApiVersionKind.is_watchable(api_ver, res_kind),
               "Expected #{api_ver} and #{res_kind} to be know types that can be watched by KubeState {#{inspect(api_ver)}, #{inspect(res_kind)}}"
      end)
    end
  end
end
