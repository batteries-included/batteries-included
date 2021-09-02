defmodule KubeResources.NetworkServiceMonitors do
  alias KubeResources.Kong

  def monitors(config) do
    Kong.monitors(config)
  end
end
