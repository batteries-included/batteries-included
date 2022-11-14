defmodule KubeExt.Defaults.Namespaces do
  def core, do: "battery-core"
  def data, do: "battery-data"
  def ml, do: "battery-ml"
  def istio, do: "battery-istio"
  def loadbalancer, do: "battery-loadbalancer"
  def knative, do: "battery-knative"
end
