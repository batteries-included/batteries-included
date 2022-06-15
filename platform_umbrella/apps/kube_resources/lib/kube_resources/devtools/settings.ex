defmodule KubeResources.DevtoolsSettings do
  @moduledoc """
  Module around turning BaseService json config into usable settings.
  """

  alias KubeRawResources.Gitea, as: GiteaRaw

  @namespace "battery-core"
  @knative_namespace "battery-knative"
  @harbor_namespace "battery-harbor"
  @knative_operator_image "gcr.io/knative-releases/knative.dev/operator/cmd/operator"
  @knative_operator_version "v1.5.0"

  @gitea_image "gitea/gitea"
  @gitea_version "1.16.4"

  def namespace(config), do: Map.get(config, "namespace", @namespace)
  def gh_enabled(config), do: Map.get(config, "runner.enabled", false)

  def gh_app_id(config), do: Map.get(config, "runner.appid", "113520")
  def gh_install_id(config), do: Map.get(config, "runner.install_id", "16687509")

  def knative_operator_image(config),
    do: Map.get(config, "knative.operator_image", @knative_operator_image)

  def knative_operator_version(config),
    do: Map.get(config, "knative.operator_version", @knative_operator_version)

  def knative_destination_namespace(config),
    do: Map.get(config, "knative.desination_namespace", @knative_namespace)

  def harbor_destination_namespace(config),
    do: Map.get(config, "harbor.desination_namespace", @harbor_namespace)

  def gh_private_key(config),
    do:
      Map.get(
        config,
        "runner.priv_key",
        ""
      )

  def gitea_image(config), do: Map.get(config, "gitea.image", @gitea_image)
  def gitea_version(config), do: Map.get(config, "gitea.version", @gitea_version)

  def gitea_user_secret_name(_config) do
    user = GiteaRaw.db_username()
    team = GiteaRaw.db_team()
    cluster_name = GiteaRaw.db_name()

    "#{user}.#{team}-#{cluster_name}.credentials.postgresql.acid.zalan.do"
  end
end
