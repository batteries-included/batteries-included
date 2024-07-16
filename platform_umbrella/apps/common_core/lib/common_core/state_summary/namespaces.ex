defmodule CommonCore.StateSummary.Namespaces do
  @moduledoc false
  import CommonCore.StateSummary.Core

  alias CommonCore.StateSummary

  @spec core_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def core_namespace(%StateSummary{} = summary), do: config_field(summary, :core_namespace)

  @spec base_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def base_namespace(%StateSummary{} = summary), do: config_field(summary, :base_namespace)

  @spec istio_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def istio_namespace(%StateSummary{} = summary), do: battery_namespace(summary, :istio)

  #
  # User Namespaces
  # These namespaces exist to put stuff that users will
  # run here.
  #
  # Databases
  # Notebooks
  # etc
  @spec ai_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def ai_namespace(%StateSummary{} = summary), do: config_field(summary, :ai_namespace)

  @spec data_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def data_namespace(%StateSummary{} = summary), do: config_field(summary, :data_namespace)

  @spec knative_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def knative_namespace(%StateSummary{} = summary), do: battery_namespace(summary, :knative)

  @spec backend_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def backend_namespace(%StateSummary{} = summary), do: battery_namespace(summary, :traditional_services)

  @spec battery_namespace(CommonCore.StateSummary.t(), atom()) :: binary() | nil
  defp battery_namespace(summary, battery) do
    case get_battery(summary, battery) do
      %{config: config} ->
        config.namespace

      _ ->
        nil
    end
  end
end
