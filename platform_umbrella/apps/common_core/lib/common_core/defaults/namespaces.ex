defmodule CommonCore.Defaults.Namespaces do
  @moduledoc false
  def core, do: "battery-core"
  def base, do: "battery-base"
  def data, do: "battery-data"
  def ai, do: "battery-ai"
  def istio, do: "battery-istio"
  def knative, do: "battery-knative"
  def backend, do: "battery-backend"

  def humanize("battery-ai"), do: "AI"

  def humanize(ns) do
    ns
    |> String.trim_leading("battery-")
    |> Phoenix.Naming.humanize()
  end
end
