defmodule CommonCore.Resources.FieldAccessorsTest do
  use ExUnit.Case

  import CommonCore.Resources.FieldAccessors

  test "uid/1 returns the UID from the resource" do
    resource = %{"metadata" => %{"uid" => "abc123"}}
    assert uid(resource) == "abc123"
  end

  test "uid/1 returns nil if no UID exists" do
    resource = %{}
    assert uid(resource) == nil
  end

  test "conditions/1 returns conditions list" do
    resource = %{"status" => %{"conditions" => [%{type: "Ready"}]}}
    assert length(conditions(resource)) == 1
  end

  test "conditions/1 returns empty list if no conditions exist" do
    resource = %{}
    assert conditions(resource) == []
  end

  test "phase/1 returns the phase" do
    resource = %{"status" => %{"phase" => "Pending"}}
    assert phase(resource) == "Pending"
  end

  test "phase/1 returns nil if no phase exists" do
    resource = %{}
    assert phase(resource) == nil
  end

  test "replicas/1 returns the replica count" do
    resource = %{"spec" => %{"replicas" => 3}}
    assert replicas(resource) == 3
  end

  test "replicas/1 returns nil if no replicas exist" do
    resource = %{}
    assert replicas(resource) == nil
  end

  test "available_replicas/1 returns the available replica count" do
    resource = %{"status" => %{"availableReplicas" => 2}}
    assert available_replicas(resource) == 2
  end

  test "available_replicas/1 returns nil if no available replica count exists" do
    resource = %{}
    assert available_replicas(resource) == nil
  end

  test "group/1 returns the correct group" do
    Enum.map(
      [
        # a whole bunch of api versions and their group
        {"acme.cert-manager.io/v1", "acme.cert-manager.io"},
        {"admissionregistration.k8s.io/v1", "admissionregistration.k8s.io"},
        {"apiextensions.k8s.io/v1", "apiextensions.k8s.io"},
        {"apiregistration.k8s.io/v1", "apiregistration.k8s.io"},
        {"apps/v1", "apps"},
        {"authentication.k8s.io/v1", "authentication.k8s.io"},
        {"authorization.k8s.io/v1", "authorization.k8s.io"},
        {"autoscaling/v2", "autoscaling"},
        {"batch/v1", "batch"},
        {"certificates.k8s.io/v1", "certificates.k8s.io"},
        {"cert-manager.io/v1", "cert-manager.io"},
        {"coordination.k8s.io/v1", "coordination.k8s.io"},
        {"crd.k8s.amazonaws.com/v1alpha1", "crd.k8s.amazonaws.com"},
        {"discovery.k8s.io/v1", "discovery.k8s.io"},
        {"elbv2.k8s.aws/v1beta1", "elbv2.k8s.aws"},
        {"events.k8s.io/v1", "events.k8s.io"},
        {"extensions.istio.io/v1alpha1", "extensions.istio.io"},
        {"flowcontrol.apiserver.k8s.io/v1", "flowcontrol.apiserver.k8s.io"},
        {"install.istio.io/v1alpha1", "install.istio.io"},
        {"karpenter.k8s.aws/v1alpha1", "karpenter.k8s.aws"},
        {"karpenter.k8s.aws/v1beta1", "karpenter.k8s.aws"},
        {"karpenter.sh/v1alpha5", "karpenter.sh"},
        {"karpenter.sh/v1beta1", "karpenter.sh"},
        {"networking.istio.io/v1alpha3", "networking.istio.io"},
        {"networking.istio.io/v1beta1", "networking.istio.io"},
        {"networking.k8s.aws/v1alpha1", "networking.k8s.aws"},
        {"networking.k8s.io/v1", "networking.k8s.io"},
        {"node.k8s.io/v1", "node.k8s.io"},
        {"policy/v1", "policy"},
        {"postgresql.cnpg.io/v1", "postgresql.cnpg.io"},
        {"rbac.authorization.k8s.io/v1", "rbac.authorization.k8s.io"},
        {"scheduling.k8s.io/v1", "scheduling.k8s.io"},
        {"security.istio.io/v1", "security.istio.io"},
        {"security.istio.io/v1beta1", "security.istio.io"},
        {"storage.k8s.io/v1", "storage.k8s.io"},
        {"telemetry.istio.io/v1alpha1", "telemetry.istio.io"},
        {"v1", "core"},
        {"vpcresources.k8s.aws/v1alpha1", "vpcresources.k8s.aws"},
        {"vpcresources.k8s.aws/v1beta1", "vpcresources.k8s.aws"}
      ],
      fn {apiversion, expected} -> assert group(%{"apiVersion" => apiversion}) == expected end
    )
  end
end
