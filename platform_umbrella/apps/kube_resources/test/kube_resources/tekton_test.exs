defmodule KubeResources.TektonTest do
  use ControlServer.DataCase, async: false

  describe "tekton resource" do
    test "CRD's should have namespace set." do
      test_namespace = "battery-test-value"
      crds = KubeResources.Tekton.crd(%{"namespace" => test_namespace})

      Enum.each(crds, fn %{"spec" => spec} = _crd ->
        case spec do
          %{"conversion" => %{"webhook" => %{"clientConfig" => %{"service" => service}}}} ->
            assert %{"name" => "tekton-pipelines-webhook", "namespace" => test_namespace} ==
                     service

          _ ->
            assert true
        end
      end)
    end
  end
end
