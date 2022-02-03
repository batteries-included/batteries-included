defmodule KubeResources.DevtoolsSettings do
  @moduledoc """
  Module around turning BaseService json config into usable settings.
  """
  @namespace "battery-core"
  @knative_namespace "battery-knative"
  @knative_operator_image "gcr.io/knative-releases/knative.dev/operator/cmd/operator"
  @knative_operator_version "sha256:8105b8c19e15bfcdd254702766a6a935f8c645ccc9c05d622ede2d4d1d6c9806"

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

  def gh_private_key(config),
    do:
      Map.get(
        config,
        "runner.priv_key",
        ""
      )
end
