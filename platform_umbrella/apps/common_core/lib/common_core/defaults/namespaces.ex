defmodule CommonCore.Defaults.Namespaces do
  @moduledoc false

  def core, do: "battery-core"
  def base, do: "battery-base"
  def data, do: "battery-data"
  def ai, do: "battery-ai"
  def istio, do: "battery-istio"
  def knative, do: "battery-knative"
  def traditional, do: "battery-traditional"

  def humanize("battery-core"), do: "Core"
  def humanize("battery-base"), do: "Base"
  def humanize("battery-data"), do: "Data"
  def humanize("battery-ai"), do: "AI"
  def humanize("battery-istio"), do: "Istio"
  def humanize("battery-knative"), do: "Knative"
  def humanize("battery-traditional"), do: "Traditional"
end
