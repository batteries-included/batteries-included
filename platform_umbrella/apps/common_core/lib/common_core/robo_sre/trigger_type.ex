defmodule CommonCore.RoboSRE.TriggerType do
  @moduledoc """
  Ecto enum for RoboSRE trigger types.
  """

  use CommonCore.Ecto.Enum,
    kubernetes_event: "kubernetes_event",
    metric_threshold: "metric_threshold",
    health_check: "health_check",
    log_pattern: "log_pattern",
    external_alert: "external_alert"

  @spec options() :: list({String.t(), t()})
  def options do
    [
      {"Kubernetes Event", :kubernetes_event},
      {"Metric Threshold", :metric_threshold},
      {"Health Check", :health_check},
      {"Log Pattern", :log_pattern},
      {"External Alert", :external_alert}
    ]
  end

  @spec label(t()) :: String.t()
  def label(:kubernetes_event), do: "Kubernetes Event"
  def label(:metric_threshold), do: "Metric Threshold"
  def label(:health_check), do: "Health Check"
  def label(:log_pattern), do: "Log Pattern"
  def label(:external_alert), do: "External Alert"

  def label(other),
    do:
      other |> Atom.to_string() |> String.replace("_", " ") |> String.split() |> Enum.map_join(" ", &String.capitalize/1)
end
