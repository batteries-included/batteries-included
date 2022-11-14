defmodule KubeResources.SecuritySettings do
  @moduledoc """
  Module around turning json config into usable settings.
  """
  import KubeExt.MapSettings

  @ory_hydra_image "oryd/hydra:v1.10.5"
  @ory_maester_image "oryd/hydra-maester:v0.0.25"

  setting(:ory_hydra_image, :image, @ory_hydra_image)
  setting(:ory_maester_image, :maester_image, @ory_maester_image)
  setting(:ory_secrets_cookie, :cookie, "Eh3xt9u8unHK4RIOnpuUwSu7a1e3liXF")
  setting(:ory_secrets_system, :secret, "OfINHFc2u50NCXXv5r9OJXLyTR0oiK9p")
end
