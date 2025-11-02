defmodule Verify.RageTest do
  use Verify.TestCase, async: false

  require Logger

  verify "bi rage collects comprehensive installation state", %{
    slug: slug,
    kind_install_worker: kind_worker_pid
  } do
    # Execute rage command using KindInstallWorker API
    {:ok, rage_json} = Verify.KindInstallWorker.rage(kind_worker_pid, slug)
    Logger.debug("Rage command returned JSON content")

    # Parse and validate the JSON structure
    rage_data = Jason.decode!(rage_json)

    # Basic structure validation
    assert %{
             "InstallSlug" => ^slug,
             "KubeExists" => true,
             "PodsInfo" => pods_info,
             "HttpRoutes" => http_routes,
             "AccessSpec" => access_spec,
             "Metrics" => metrics,
             "Nodes" => nodes,
             "BILogs" => bi_logs
           } = rage_data

    # Validate metrics were collected
    assert %{
             "metrics" => _metrics_data,
             "collected_at" => collected_at
           } = metrics

    assert is_binary(collected_at), "Collection timestamp should be present"

    # Validate pod information exists (should have core batteries running)
    assert is_list(pods_info), "Pods info should be a list"
    assert length(pods_info) > 0, "Should have at least some pods running"

    # Validate HTTP routes exist (control server route should exist)
    assert is_list(http_routes), "HTTP routes should be a list"
    assert length(http_routes) > 0, "Should have at least control server route"

    # Validate access spec exists
    assert %{"hostname" => _hostname, "ssl" => _ssl} = access_spec

    # Validate node information
    assert is_list(nodes), "Nodes should be a list"
    assert length(nodes) > 0, "Should have at least one node"

    # Validate BI logs exist
    assert is_map(bi_logs), "BI logs should be a map"
  end
end
