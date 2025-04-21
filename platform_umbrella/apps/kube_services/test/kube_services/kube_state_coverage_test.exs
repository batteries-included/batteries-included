defmodule KubeServices.KubeStateCoverageTest do
  use ExUnit.Case

  import CommonCore.Factory
  import K8s.Resource.FieldAccessors

  alias CommonCore.ApiVersionKind
  alias CommonCore.Resources.RootResourceGenerator

  # We open up a watcher for each type.
  # Some types aren't worth the http connections
  @ignored_crd_types [
    # This is not able to be used well in oss environments
    {"operator.victoriametrics.com/v1beta1", "VMAuth"},
    {"operator.victoriametrics.com/v1beta1", "VMUser"},

    # Cloudnative PG Ignored for now.
    # This is for the configuration of logical replication
    # We don't have that currently.
    {"postgresql.cnpg.io/v1", "Publication"},
    {"postgresql.cnpg.io/v1", "Subscription"},

    # This is for images. Since control server handles that we don't use it
    {"postgresql.cnpg.io/v1", "ClusterImageCatalog"},
    {"postgresql.cnpg.io/v1", "ImageCatalog"},

    # We don't emit or display these
    {"elbv2.k8s.aws/v1beta1", "TargetGroupBinding"},
    {"karpenter.sh/v1beta1", "NodeClaim"},

    # BGP will come later
    {"metallb.io/v1beta1", "BGPAdvertisement"},
    {"metallb.io/v1beta2", "BGPPeer"},
    {"metallb.io/v1beta1", "Community"},
    {"metallb.io/v1beta1", "BFDProfile"},
    {"metallb.io/v1beta1", "ServiceL2Status"},

    # Istio has EVERYTHING
    {"networking.istio.io/v1beta1", "WorkloadGroup"},
    {"networking.istio.io/v1beta1", "WorkloadEntry"},
    {"networking.istio.io/v1beta1", "ServiceEntry"},
    {"networking.istio.io/v1beta1", "DestinationRule"},
    {"networking.istio.io/v1beta1", "Sidecar"},
    {"networking.istio.io/v1beta1", "ProxyConfig"},

    # Knative is choosing that route too.
    {"operator.knative.dev/v1beta1", "KnativeEventing"},
    {"install.istio.io/v1alpha1", "IstioOperator"},
    {"autoscaling.internal.knative.dev/v1alpha1", "PodAutoscaler"},
    {"autoscaling.internal.knative.dev/v1alpha1", "Metric"},
    {"networking.internal.knative.dev/v1alpha1", "Certificate"},
    {"serving.knative.dev/v1beta1", "DomainMapping"},
    {"networking.internal.knative.dev/v1alpha1", "ClusterDomainClaim"},
    {"networking.internal.knative.dev/v1alpha1", "Ingress"},
    {"networking.internal.knative.dev/v1alpha1", "ServerlessService"}
  ]

  describe "KubeState can watch for every battery" do
    @tag :slow
    test "All watchable" do
      :install_spec
      |> build(usage: :kitchen_sink, kube_provider: :kind, default_size: :huge)
      |> then(fn spec -> spec.target_summary end)
      |> RootResourceGenerator.materialize()
      |> Enum.map(fn {_path, resource} -> {api_version(resource), kind(resource)} end)
      |> Enum.each(fn {api_version, kind} ->
        assert ApiVersionKind.watchable?(api_version, kind),
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

    @tag :slow
    test "All CRD's watchable" do
      :install_spec
      |> build(usage: :kitchen_sink)
      |> then(fn spec -> spec.target_summary end)
      |> RootResourceGenerator.materialize()
      |> Enum.filter(fn {_path, resource} -> ApiVersionKind.resource_type!(resource) == :crd end)
      |> Enum.map(fn {_path, crd} ->
        extract_crd_ver_kind(crd)
      end)
      |> Enum.reject(fn v -> Enum.member?(@ignored_crd_types, v) end)
      |> Enum.sort()
      |> Enum.uniq()
      |> Enum.each(fn {api_ver, res_kind} ->
        assert ApiVersionKind.watchable?(api_ver, res_kind),
               "Expected #{api_ver} and #{res_kind} to be know types that can be watched by KubeState {#{inspect(api_ver)}, #{inspect(res_kind)}}"
      end)
    end
  end
end
