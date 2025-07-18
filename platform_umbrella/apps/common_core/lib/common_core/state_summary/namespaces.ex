defmodule CommonCore.StateSummary.Namespaces do
  @moduledoc false
  import CommonCore.StateSummary.Batteries, only: [get_battery: 2]
  import CommonCore.StateSummary.Core, only: [config_field: 2]

  alias CommonCore.StateSummary

  @spec core_namespace(StateSummary.t()) :: binary() | nil
  def core_namespace(%StateSummary{} = summary), do: config_field(summary, :core_namespace)

  @spec base_namespace(StateSummary.t()) :: binary() | nil
  def base_namespace(%StateSummary{} = summary), do: config_field(summary, :base_namespace)

  @spec istio_namespace(StateSummary.t()) :: binary() | nil
  def istio_namespace(%StateSummary{} = summary), do: battery_namespace(summary, :istio)

  def all_namespaces(%StateSummary{} = summary) do
    Enum.reject(
      [
        ai_namespace(summary),
        data_namespace(summary),
        knative_namespace(summary),
        traditional_namespace(summary),
        core_namespace(summary),
        base_namespace(summary),
        istio_namespace(summary)
      ],
      &is_nil/1
    )
  end

  #
  # User Namespaces
  # These namespaces exist to put stuff that users will
  # run here.
  #
  # Databases
  # Notebooks
  # etc
  @spec ai_namespace(StateSummary.t()) :: binary() | nil
  def ai_namespace(%StateSummary{} = summary), do: config_field(summary, :ai_namespace)

  @spec data_namespace(StateSummary.t()) :: binary() | nil
  def data_namespace(%StateSummary{} = summary), do: config_field(summary, :data_namespace)

  @spec knative_namespace(StateSummary.t()) :: binary() | nil
  def knative_namespace(%StateSummary{} = summary), do: battery_namespace(summary, :knative)

  @spec traditional_namespace(StateSummary.t()) :: binary() | nil
  def traditional_namespace(%StateSummary{} = summary), do: battery_namespace(summary, :traditional_services)

  @spec battery_namespace(StateSummary.t(), atom()) :: binary() | nil
  def battery_namespace(summary, battery) do
    case get_battery(summary, battery) do
      %{config: config} ->
        config.namespace

      _ ->
        nil
    end
  end
end
