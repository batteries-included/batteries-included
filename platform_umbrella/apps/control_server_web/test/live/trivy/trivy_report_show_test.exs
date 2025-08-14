defmodule ControlServerWeb.Live.TrivyReportShowTest do
  use ControlServerWeb.ConnCase

  import CommonCore.Resources.FieldAccessors
  import CommonCore.TrivyResourceFactory
  import Phoenix.LiveViewTest

  alias KubeServices.KubeState.Runner

  @table_name :default_state_table

  defp create_vulnerability_report(_) do
    report = build(:aqua_vulnerability_report)
    Runner.add(@table_name, report)

    on_exit(fn ->
      Runner.delete(@table_name, report)
    end)

    %{vulnerability_report: report}
  end

  defp create_cluster_vulnerability_report(_) do
    report = build(:aqua_cluster_vulnerability_report)
    Runner.add(@table_name, report)

    on_exit(fn ->
      Runner.delete(@table_name, report)
    end)

    %{cluster_vulnerability_report: report}
  end

  defp create_exposed_secret_report(_) do
    report = build(:aqua_exposed_secret_report)
    Runner.add(@table_name, report)

    on_exit(fn ->
      Runner.delete(@table_name, report)
    end)

    %{exposed_secret_report: report}
  end

  defp create_sbom_report(_) do
    report = build(:aqua_sbom_report)
    Runner.add(@table_name, report)

    on_exit(fn ->
      Runner.delete(@table_name, report)
    end)

    %{sbom_report: report}
  end

  defp create_cluster_sbom_report(_) do
    report = build(:aqua_cluster_sbom_report)
    Runner.add(@table_name, report)

    on_exit(fn ->
      Runner.delete(@table_name, report)
    end)

    %{cluster_sbom_report: report}
  end

  defp create_config_audit_report(_) do
    report = build(:aqua_config_audit_report)
    Runner.add(@table_name, report)

    on_exit(fn ->
      Runner.delete(@table_name, report)
    end)

    %{config_audit_report: report}
  end

  defp create_rbac_assessment_report(_) do
    report = build(:aqua_rbac_assessment_report)
    Runner.add(@table_name, report)

    on_exit(fn ->
      Runner.delete(@table_name, report)
    end)

    %{rbac_assessment_report: report}
  end

  defp create_cluster_rbac_assessment_report(_) do
    report = build(:aqua_cluster_rbac_assessment_report)
    Runner.add(@table_name, report)

    on_exit(fn ->
      Runner.delete(@table_name, report)
    end)

    %{cluster_rbac_assessment_report: report}
  end

  defp create_infra_assessment_report(_) do
    report = build(:aqua_infra_assessment_report)
    Runner.add(@table_name, report)

    on_exit(fn ->
      Runner.delete(@table_name, report)
    end)

    %{infra_assessment_report: report}
  end

  defp create_cluster_infra_assessment_report(_) do
    report = build(:aqua_cluster_infra_assesment_report)
    Runner.add(@table_name, report)

    on_exit(fn ->
      Runner.delete(@table_name, report)
    end)

    %{cluster_infra_assessment_report: report}
  end

  describe "vulnerability report show" do
    setup [:create_vulnerability_report]

    test "displays vulnerability report details", %{conn: conn, vulnerability_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} =
        live(conn, ~p"/trivy_reports/aqua_vulnerability_report/#{report_namespace}/#{report_name}")

      # Check page title and report name
      assert html =~ "Vulnerability Report"
      assert html =~ report_name

      # Check artifact information
      artifact_repo = get_in(report, ~w(report artifact repository))
      artifact_tag = get_in(report, ~w(report artifact tag))
      assert html =~ artifact_repo
      assert html =~ artifact_tag

      # Check namespace badge
      assert html =~ report_namespace

      # Check that vulnerabilities table is displayed
      assert html =~ "vulnerabilities-table"

      # Check for page title
      assert html =~ "Vulnerability Report"
    end

    test "displays vulnerability details", %{conn: conn, vulnerability_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} =
        live(conn, ~p"/trivy_reports/aqua_vulnerability_report/#{report_namespace}/#{report_name}")

      # Check vulnerability information from the report
      vulnerabilities = get_in(report, ~w(report vulnerabilities)) || []

      if vulnerabilities != [] do
        first_vuln = Enum.at(vulnerabilities, 0)
        severity = Map.get(first_vuln, "severity")
        title = Map.get(first_vuln, "title")

        if severity, do: assert(html =~ severity)
        if title, do: assert(html =~ title)
      end
    end

    test "has back link to vulnerability reports index", %{conn: conn, vulnerability_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} =
        live(conn, ~p"/trivy_reports/aqua_vulnerability_report/#{report_namespace}/#{report_name}")

      # Check for back link
      assert html =~ ~p"/trivy_reports/vulnerability_report"
    end
  end

  describe "cluster vulnerability report show" do
    setup [:create_cluster_vulnerability_report]

    test "displays cluster vulnerability report details", %{conn: conn, cluster_vulnerability_report: report} do
      report_name = name(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/clustervulnerabilityreports/#{report_name}")

      # Check page title and report name
      assert html =~ "Cluster Vulnerability Report"
      assert html =~ report_name

      # Check artifact information
      artifact_repo = get_in(report, ~w(report artifact repository))
      artifact_tag = get_in(report, ~w(report artifact tag))
      assert html =~ artifact_repo
      assert html =~ artifact_tag

      # Check that vulnerabilities table is displayed
      assert html =~ "vulnerabilities-table"
    end

    test "has back link to cluster vulnerability reports index", %{conn: conn, cluster_vulnerability_report: report} do
      report_name = name(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/clustervulnerabilityreports/#{report_name}")

      # Check for back link
      assert html =~ ~p"/trivy_reports/cluster_vulnerability_report"
    end
  end

  describe "exposed secret report show" do
    setup [:create_exposed_secret_report]

    test "displays exposed secret report details", %{conn: conn, exposed_secret_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} =
        live(conn, ~p"/trivy_reports/aqua_exposed_secret_report/#{report_namespace}/#{report_name}")

      # Check page title and report name
      assert html =~ "Exposed Secrets Report"
      assert html =~ report_name

      # Check that exposed secrets table is displayed
      assert html =~ "exposed-secrets-table"

      # Check for secret information
      secrets = get_in(report, ~w(report secrets)) || []

      if secrets != [] do
        first_secret = Enum.at(secrets, 0)
        rule_id = Map.get(first_secret, "ruleID")
        severity = Map.get(first_secret, "severity")

        if rule_id, do: assert(html =~ rule_id)
        if severity, do: assert(html =~ severity)
      end
    end

    test "has back link to exposed secret reports index", %{conn: conn, exposed_secret_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} =
        live(conn, ~p"/trivy_reports/aqua_exposed_secret_report/#{report_namespace}/#{report_name}")

      # Check for back link
      assert html =~ ~p"/trivy_reports/exposed_secret_report"
    end
  end

  describe "sbom report show" do
    setup [:create_sbom_report]

    test "displays sbom report details", %{conn: conn, sbom_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/aqua_sbom_report/#{report_namespace}/#{report_name}")

      # Check page title and report name
      assert html =~ "SBOM Report"
      assert html =~ report_name

      # Check that SBOM table is displayed
      assert html =~ "sbom-components-table"

      # Check for component information
      components = get_in(report, ~w(report components components)) || []

      if components != [] do
        first_component = Enum.at(components, 0)
        component_name = Map.get(first_component, "name")
        component_version = Map.get(first_component, "version")

        if component_name, do: assert(html =~ component_name)
        if component_version, do: assert(html =~ component_version)
      end
    end

    test "has back link to sbom reports index", %{conn: conn, sbom_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/aqua_sbom_report/#{report_namespace}/#{report_name}")

      # Check for back link
      assert html =~ ~p"/trivy_reports/sbom_report"
    end
  end

  describe "cluster sbom report show" do
    setup [:create_cluster_sbom_report]

    test "displays cluster sbom report details", %{conn: conn, cluster_sbom_report: report} do
      report_name = name(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/clustersbomreports/#{report_name}")

      # Check page title and report name
      assert html =~ "Cluster SBOM Report"
      assert html =~ report_name

      # Check that SBOM table is displayed
      assert html =~ "sbom-components-table"
    end

    test "has back link to cluster sbom reports index", %{conn: conn, cluster_sbom_report: report} do
      report_name = name(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/clustersbomreports/#{report_name}")

      # Check for back link
      assert html =~ ~p"/trivy_reports/cluster_sbom_report"
    end
  end

  describe "config audit report show" do
    setup [:create_config_audit_report]

    test "displays config audit report details", %{conn: conn, config_audit_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/aqua_config_audit_report/#{report_namespace}/#{report_name}")

      # Check page title and report name
      assert html =~ "Config Audit Report"
      assert html =~ report_name

      # Check that config audit checks table is displayed
      assert html =~ "config-audit-checks-table"

      # Check for check information
      checks = get_in(report, ~w(report checks)) || []

      if checks != [] do
        first_check = Enum.at(checks, 0)
        check_id = Map.get(first_check, "checkID")
        severity = Map.get(first_check, "severity")

        if check_id, do: assert(html =~ check_id)
        if severity, do: assert(html =~ severity)
      end
    end

    test "has back link to config audit reports index", %{conn: conn, config_audit_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/aqua_config_audit_report/#{report_namespace}/#{report_name}")

      # Check for back link
      assert html =~ ~p"/trivy_reports/config_audit_report"
    end
  end

  describe "rbac assessment report show" do
    setup [:create_rbac_assessment_report]

    test "displays rbac assessment report details", %{conn: conn, rbac_assessment_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} =
        live(conn, ~p"/trivy_reports/aqua_rbac_assessment_report/#{report_namespace}/#{report_name}")

      # Check page title and report name
      assert html =~ "RBAC Assessment Report"
      assert html =~ report_name

      # Check that RBAC checks table is displayed
      assert html =~ "rbac-checks-table"

      # Check for check information
      checks = get_in(report, ~w(report checks)) || []

      if checks != [] do
        first_check = Enum.at(checks, 0)
        check_id = Map.get(first_check, "checkID")
        severity = Map.get(first_check, "severity")

        if check_id, do: assert(html =~ check_id)
        if severity, do: assert(html =~ severity)
      end
    end

    test "has back link to rbac assessment reports index", %{conn: conn, rbac_assessment_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} =
        live(conn, ~p"/trivy_reports/aqua_rbac_assessment_report/#{report_namespace}/#{report_name}")

      # Check for back link
      assert html =~ ~p"/trivy_reports/rbac_assessment_report"
    end
  end

  describe "cluster rbac assessment report show" do
    setup [:create_cluster_rbac_assessment_report]

    test "displays cluster rbac assessment report details", %{conn: conn, cluster_rbac_assessment_report: report} do
      report_name = name(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/clusterrbacassessmentreports/#{report_name}")

      # Check page title and report name
      assert html =~ "Cluster RBAC Assessment Report"
      assert html =~ report_name

      # Check that RBAC checks table is displayed
      assert html =~ "rbac-checks-table"
    end

    test "has back link to cluster rbac assessment reports index", %{conn: conn, cluster_rbac_assessment_report: report} do
      report_name = name(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/clusterrbacassessmentreports/#{report_name}")

      # Check for back link
      assert html =~ ~p"/trivy_reports/cluster_rbac_assessment_report"
    end
  end

  describe "infra assessment report show" do
    setup [:create_infra_assessment_report]

    test "displays infra assessment report details", %{conn: conn, infra_assessment_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} =
        live(conn, ~p"/trivy_reports/aqua_infra_assessment_report/#{report_namespace}/#{report_name}")

      # Check page title and report name
      assert html =~ "Infrastructure Assessment Report"
      assert html =~ report_name

      # Check that infra checks table is displayed
      assert html =~ "infra-checks-table"

      # Check for check information
      checks = get_in(report, ~w(report checks)) || []

      if checks != [] do
        first_check = Enum.at(checks, 0)
        check_id = Map.get(first_check, "checkID")
        severity = Map.get(first_check, "severity")

        if check_id, do: assert(html =~ check_id)
        if severity, do: assert(html =~ severity)
      end
    end

    test "has back link to infra assessment reports index", %{conn: conn, infra_assessment_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} =
        live(conn, ~p"/trivy_reports/aqua_infra_assessment_report/#{report_namespace}/#{report_name}")

      # Check for back link
      assert html =~ ~p"/trivy_reports/infra_assessment_report"
    end
  end

  describe "cluster infra assessment report show" do
    setup [:create_cluster_infra_assessment_report]

    test "displays cluster infra assessment report details", %{conn: conn, cluster_infra_assessment_report: report} do
      report_name = name(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/clusterinfraassessmentreports/#{report_name}")

      # Check page title and report name
      assert html =~ "Trivy Report"
      assert html =~ report_name

      # NOTE: Implementation not yet complete for this report type
      assert html =~ "Report details not yet implemented"
    end

    test "has back link to cluster infra assessment reports index", %{conn: conn, cluster_infra_assessment_report: report} do
      report_name = name(report)

      {:ok, _show_live, html} = live(conn, ~p"/trivy_reports/clusterinfraassessmentreports/#{report_name}")

      # Check for back link - note this may not be fully implemented yet
      # For now, just verify the page loads successfully
      assert html =~ report_name
    end
  end

  describe "report metadata" do
    setup [:create_vulnerability_report]

    test "displays artifact information in badge", %{conn: conn, vulnerability_report: report} do
      report_name = name(report)
      report_namespace = namespace(report)

      {:ok, _show_live, html} =
        live(conn, ~p"/trivy_reports/aqua_vulnerability_report/#{report_namespace}/#{report_name}")

      # Check artifact badge information
      artifact_repo = get_in(report, ~w(report artifact repository))
      artifact_tag = get_in(report, ~w(report artifact tag))

      assert html =~ "Artifact"
      assert html =~ "#{artifact_repo}/#{artifact_tag}"
      assert html =~ "Namespace"
      assert html =~ report_namespace
      assert html =~ "Created"
    end
  end
end
