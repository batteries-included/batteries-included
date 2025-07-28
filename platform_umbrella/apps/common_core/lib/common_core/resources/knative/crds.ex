defmodule CommonCore.Resources.KnativeServingCRDs do
  @moduledoc false
  use CommonCore.IncludeResource,
    certificates_networking_internal_knative_dev:
      "priv/manifests/knative-serving/certificates_networking_internal_knative_dev.yaml",
    clusterdomainclaims_networking_internal_knative_dev:
      "priv/manifests/knative-serving/clusterdomainclaims_networking_internal_knative_dev.yaml",
    configurations_serving_knative_dev: "priv/manifests/knative-serving/configurations_serving_knative_dev.yaml",
    domainmappings_serving_knative_dev: "priv/manifests/knative-serving/domainmappings_serving_knative_dev.yaml",
    images_caching_internal_knative_dev: "priv/manifests/knative-serving/images_caching_internal_knative_dev.yaml",
    ingresses_networking_internal_knative_dev:
      "priv/manifests/knative-serving/ingresses_networking_internal_knative_dev.yaml",
    metrics_autoscaling_internal_knative_dev:
      "priv/manifests/knative-serving/metrics_autoscaling_internal_knative_dev.yaml",
    podautoscalers_autoscaling_internal_knative_dev:
      "priv/manifests/knative-serving/podautoscalers_autoscaling_internal_knative_dev.yaml",
    revisions_serving_knative_dev: "priv/manifests/knative-serving/revisions_serving_knative_dev.yaml",
    routes_serving_knative_dev: "priv/manifests/knative-serving/routes_serving_knative_dev.yaml",
    serverlessservices_networking_internal_knative_dev:
      "priv/manifests/knative-serving/serverlessservices_networking_internal_knative_dev.yaml",
    services_serving_knative_dev: "priv/manifests/knative-serving/services_serving_knative_dev.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "knative-serving"

  multi_resource(:crds_knative) do
    Enum.flat_map(@included_resources, &(&1 |> get_resource() |> YamlElixir.read_all_from_string!()))
  end
end
