defmodule Verify.TrivyTest do
  use Verify.TestCase,
    async: false,
    batteries: ~w(trivy_operator)a,
    images: ~w(trivy_operator aqua_trivy aqua_node_collector)a

  @trivy_report_path "/trivy_reports/vulnerability_report"
  @config_audit_link Query.link("Config Audit")
  @cluster_rbac_link Query.link("Cluster RBAC")
  @cluster_sbom_link Query.link("Cluster SBOM")
  @cluster_vuln_link Query.link("Cluster Vuln")
  @exposed_secrets_link Query.link("Exposed Secrets")
  # wallaby will find Cluster RBAC and RBAC if we try to use link like above
  @rbac_link Query.css(~s|a[href="/trivy_reports/rbac_assessment_report"]|)
  @sbom_link Query.css(~s|a[href="/trivy_reports/sbom_report"]|)
  @kube_infra_link Query.link("Kube Infra")
  @vulnerability_link Query.link("Vulnerability")

  # TODO: use this module to assert that there are no vulnerabilities?

  setup_all %{control_url: url} do
    wrap do
      {:ok, session} = start_session(url)

      session
      # make sure operator is running
      |> assert_pod_running("trivy-operator")
      # wait until the reports have ran
      |> visit(@trivy_report_path)
      |> then(fn session ->
        Enum.reduce(
          # this is _roughly_ in order of quickest to slowest
          # as a result, we shouldn't spend much time waiting for any single one
          [
            @cluster_sbom_link,
            @config_audit_link,
            @rbac_link,
            @cluster_rbac_link,
            @kube_infra_link,
            @cluster_vuln_link,
            @vulnerability_link,
            @exposed_secrets_link,
            @sbom_link
          ],
          session,
          fn link, s ->
            {:ok, _} =
              s
              |> sleep(121)
              |> click(link)
              # this will retry until there are rows (i.e we have results) or we time out
              |> execute_query(table_row(minimum: 1))

            s
          end
        )
      end)

      Wallaby.end_session(session)
      :ok
    end
  end

  verify "config audits ran and are visible", %{session: session} do
    session
    |> visit(@trivy_report_path)
    |> assert_has(@config_audit_link)
    |> click(@config_audit_link)
    |> assert_has(table_row(text: "service-", minimum: 1))
  end

  verify "rbac assessments ran and are visible", %{session: session} do
    session
    |> visit(@trivy_report_path)
    |> assert_has(@rbac_link)
    |> click(@rbac_link)
    |> assert_has(table_row(text: "role-", minimum: 1))
  end

  verify "cluster rbac assessments ran and are visible", %{session: session} do
    session
    |> visit(@trivy_report_path)
    |> assert_has(@cluster_rbac_link)
    |> click(@cluster_rbac_link)
    |> assert_has(table_row(text: "clusterrole-", minimum: 1))
  end

  verify "infra assessments ran and are visible", %{session: session} do
    session
    |> visit(@trivy_report_path)
    |> assert_has(@kube_infra_link)
    |> click(@kube_infra_link)
    |> assert_has(table_row(text: "pod-", minimum: 1))
  end

  verify "vulnerability reports ran and are visible", %{session: session} do
    session
    |> visit(@trivy_report_path)
    |> assert_has(@vulnerability_link)
    |> click(@vulnerability_link)
    |> assert_has(table_row(minimum: 1))
    |> find(table_row(at: 0), &click(&1, Query.css("tr td:first-child")))
    |> assert_has(table_row(minimum: 1))
  end
end
