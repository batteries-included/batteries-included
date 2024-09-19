defmodule CommonCore.ET.UsageReportTest do
  use ExUnit.Case

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.ET.KnativeReport
  alias CommonCore.ET.NamespaceReport
  alias CommonCore.ET.NodeReport
  alias CommonCore.ET.OllamaReport
  alias CommonCore.ET.PostgresReport
  alias CommonCore.ET.RedisReport
  alias CommonCore.ET.TraditionalServicesReport
  alias CommonCore.ET.UsageReport
  alias CommonCore.Projects.Project
  alias CommonCore.StateSummary

  setup do
    state_summary = %StateSummary{
      batteries: [
        SystemBattery.new!(%{type: :istio, group: :net_sec, config: %{type: :istio}}),
        SystemBattery.new!(%{type: :loki, group: :monitoring, config: %{type: :loki}})
      ],
      projects: [Project.new!(%{name: "project1"}), Project.new!(%{name: "project2"})]
    }

    {:ok, state_summary: state_summary}
  end

  test "new/1 with StateSummary", %{state_summary: state_summary} do
    report = UsageReport.new!(state_summary)

    assert report.node_report == NodeReport.new!(state_summary)
    assert report.namespace_report == NamespaceReport.new!(state_summary)
    assert report.postgres_report == PostgresReport.new!(state_summary)
    assert report.redis_report == RedisReport.new!(state_summary)
    assert report.num_projects == length(state_summary.projects)
    assert report.batteries == Enum.map(state_summary.batteries, fn battery -> to_string(battery.type) end)
  end

  test "new/1 with options map" do
    opts = %{
      node_report: %NodeReport{},
      namespace_report: %NamespaceReport{},
      postgres_report: %PostgresReport{},
      redis_report: %RedisReport{},
      knative_report: %KnativeReport{},
      traditional_services_report: %TraditionalServicesReport{},
      ollama_report: %OllamaReport{},
      num_projects: 2,
      batteries: ["istio", "loki"]
    }

    report = UsageReport.new!(opts)

    assert report.node_report == opts.node_report
    assert report.namespace_report == opts.namespace_report
    assert report.postgres_report == opts.postgres_report
    assert report.redis_report == opts.redis_report
    assert report.num_projects == opts.num_projects
    assert report.batteries == opts.batteries
  end
end
