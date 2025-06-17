defmodule CommonCore.Defaults.Images do
  @moduledoc false

  alias CommonCore.Defaults.Image

  @before_compile CommonCore.Defaults.Registry

  @batteries_included_base "#{CommonCore.Version.version()}-#{CommonCore.Version.hash()}"

  @spec get_image(atom()) :: Image.t() | nil
  def get_image(name) do
    Map.get(registry(), name, nil)
  end

  @spec get_image!(atom()) :: Image.t()
  def get_image!(name) do
    case get_image(name) do
      nil ->
        raise "Image #{name} not found"

      image ->
        image
    end
  end

  @spec batteries_included_version() :: String.t()
  def batteries_included_version do
    override =
      :common_core
      |> Application.get_env(CommonCore.Defaults)
      |> Keyword.get(:version_override, nil)

    if override == nil do
      @batteries_included_base
    else
      override
    end
  end

  @spec control_server_image() :: String.t()
  def control_server_image do
    ver = batteries_included_version()
    "ghcr.io/batteries-included/control-server:#{ver}"
  end

  @spec bootstrap_image() :: String.t()
  def bootstrap_image do
    ver = batteries_included_version()
    "ghcr.io/batteries-included/kube-bootstrap:#{ver}"
  end

  @spec home_base_image() :: String.t()
  def home_base_image do
    ver = batteries_included_version()
    "ghcr.io/batteries-included/home-base:#{ver}"
  end
end
