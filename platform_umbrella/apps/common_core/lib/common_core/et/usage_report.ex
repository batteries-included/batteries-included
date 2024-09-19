defmodule CommonCore.ET.UsageReport do
  @moduledoc false
  use CommonCore, :embedded_schema

  alias CommonCore.Ecto.Schema
  alias CommonCore.ET.KnativeReport
  alias CommonCore.ET.NamespaceReport
  alias CommonCore.ET.NodeReport
  alias CommonCore.ET.OllamaReport
  alias CommonCore.ET.PostgresReport
  alias CommonCore.ET.RedisReport
  alias CommonCore.ET.TraditionalServicesReport
  alias CommonCore.StateSummary

  @required_fields ~w(node_report namespace_report postgres_report redis_report num_projects batteries knative_report traditional_services_report)a

  batt_embedded_schema do
    embeds_one :node_report, NodeReport
    embeds_one :namespace_report, NamespaceReport
    embeds_one :postgres_report, PostgresReport
    embeds_one :redis_report, RedisReport
    embeds_one :knative_report, KnativeReport
    embeds_one :traditional_services_report, TraditionalServicesReport
    embeds_one :ollama_report, OllamaReport

    field :batteries, {:array, :string}
    field :num_projects, :integer
  end

  def new(%StateSummary{} = state_summary) do
    with {:ok, node_report} <- NodeReport.new(state_summary),
         {:ok, namespace_report} <- NamespaceReport.new(state_summary),
         {:ok, postgres_report} <- PostgresReport.new(state_summary),
         {:ok, redis_report} <- RedisReport.new(state_summary),
         {:ok, knative_report} <- KnativeReport.new(state_summary),
         {:ok, traditional_services_report} <- TraditionalServicesReport.new(state_summary),
         {:ok, ollama_report} <- OllamaReport.new(state_summary) do
      battery_names = batteries(state_summary)

      Schema.schema_new(__MODULE__,
        node_report: node_report,
        namespace_report: namespace_report,
        postgres_report: postgres_report,
        redis_report: redis_report,
        num_projects: length(state_summary.projects || []),
        knative_report: knative_report,
        traditional_services_report: traditional_services_report,
        ollama_report: ollama_report,
        batteries: battery_names
      )
    end
  end

  def new(opts) do
    Schema.schema_new(__MODULE__, opts)
  end

  defp batteries(%StateSummary{batteries: batteries} = _state_summary) do
    Enum.map(batteries, fn battery -> to_string(battery.type) end)
  end
end
