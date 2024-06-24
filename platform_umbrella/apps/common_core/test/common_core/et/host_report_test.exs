defmodule CommonCore.ET.HostReportTest do
  use ExUnit.Case

  alias CommonCore.ET.HostReport
  alias CommonCore.Projects.Project
  alias CommonCore.StateSummary

  setup do
    state_summary = %StateSummary{
      projects: [Project.new!(%{name: "project1"}), Project.new!(%{name: "project2"})]
    }

    {:ok, state_summary: state_summary}
  end

  test "new/1 with StateSummary", %{state_summary: state_summary} do
    report = HostReport.new!(state_summary)

    assert report.control_server_host == "control.127-0-0-1.ip.batteriesincl.com"
  end

  test "new/1 with options map" do
    opts = %{control_server_host: "abc"}

    report = HostReport.new!(opts)

    assert report.control_server_host == "abc"
  end
end
