defmodule KubeResources.DevtoolsSettings do
  @moduledoc """
  Module around turning json config into usable settings.
  """

  import KubeExt.MapSettings

  alias KubeExt.RequiredDatabases

  @knative_operator_image "gcr.io/knative-releases/knative.dev/operator/cmd/operator:v1.5.1"

  @gitea_image "gitea/gitea:1.16.8"

  @core_image "goharbor/harbor-core:v2.5.2"
  @portal_image "goharbor/harbor-portal:v2.5.2"
  @jobservice_image "goharbor/harbor-jobservice:v2.5.2"
  @registry_photon_image "goharbor/registry-photon:v2.5.2"
  @registry_ctl_image "goharbor/harbor-registryctl:v2.5.2"
  @trivy_adapter_image "goharbor/trivy-adapter-photon:dev"

  setting(:gh_app_id, :app_id, "113520")
  setting(:gh_install_id, :install_id, "16687509")
  setting(:gh_private_key, :private_key, "")

  setting(:knative_operator_image, :image, @knative_operator_image)

  setting(:harbor_core_image, :image, @core_image)
  setting(:harbor_portal_image, :portal_image, @portal_image)
  setting(:harbor_jobservice_image, :jobservice_image, @jobservice_image)
  setting(:harbor_registry_photon_image, :registry_photon_image, @registry_photon_image)
  setting(:harbor_registry_ctl_image, :registry_ctl_image, @registry_ctl_image)
  setting(:harbor_trivy_adapter_image, :trivy_adapter_image, @trivy_adapter_image)

  setting(:gitea_image, :image, @gitea_image)

  def gitea_pg_secret_name(_config) do
    user = RequiredDatabases.Gitea.db_username()
    team = RequiredDatabases.Gitea.db_team()
    cluster_name = RequiredDatabases.Gitea.db_name()

    "#{user}.#{team}-#{cluster_name}.credentials.postgresql.acid.zalan.do"
  end
end
