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

  resource(:crd_certificates_networking_internal_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:certificates_networking_internal_knative_dev))
  end

  resource(:crd_clusterdomainclaims_networking_internal_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:clusterdomainclaims_networking_internal_knative_dev))
  end

  resource(:crd_configurations_serving_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:configurations_serving_knative_dev))
  end

  resource(:crd_domainmappings_serving_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:domainmappings_serving_knative_dev))
  end

  resource(:crd_images_caching_internal_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:images_caching_internal_knative_dev))
  end

  resource(:crd_ingresses_networking_internal_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:ingresses_networking_internal_knative_dev))
  end

  resource(:crd_metrics_autoscaling_internal_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:metrics_autoscaling_internal_knative_dev))
  end

  resource(:crd_podautoscalers_autoscaling_internal_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:podautoscalers_autoscaling_internal_knative_dev))
  end

  resource(:crd_revisions_serving_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:revisions_serving_knative_dev))
  end

  resource(:crd_routes_serving_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:routes_serving_knative_dev))
  end

  resource(:crd_serverlessservices_networking_internal_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:serverlessservices_networking_internal_knative_dev))
  end

  resource(:crd_services_serving_knative_dev) do
    YamlElixir.read_all_from_string!(get_resource(:services_serving_knative_dev))
  end
end
