defmodule KubeServices.RoboSRE.StaleResourceHandler do
  @moduledoc """
  Handler for remediating stale resource issues.

  This handler:
  1. Deletes the stale resource from the cluster
  2. Stores the resource in the deleted resource table for potential recovery
  3. Monitors the deletion to ensure it was successful
  """

  @behaviour KubeServices.RoboSRE.Handler

  alias CommonCore.RoboSRE.Issue
  alias CommonCore.RoboSRE.RemediationPlan
  alias KubeServices.KubeState
  alias KubeServices.Stale

  require Logger

  @spec preflight(Issue.t()) :: {:ok, :ready | :skip} | {:error, any()}
  def preflight(%Issue{trigger_params: params} = issue) do
    Logger.info(
      "Preflight check for stale resource issue (issue_id: #{issue.id}, subject: #{issue.subject} params: #{inspect(params)})"
    )

    {api_version_kind, namespace, name} = destructure_params(issue)
    # We have to get the resource again to since we only pass the identifying info in trigger_params
    # and we need the labels and annotations as they currently exist on the resource
    with {:ok, resource} <- KubeState.get(api_version_kind, namespace, name),
         true <- Stale.stale?(resource) do
      {:ok, :ready}
    else
      :missing ->
        {:ok, :skip}

      false ->
        {:error, :not_stale}
    end
  end

  @doc """
  Create a remediation plan for a stale resource issue.
  """
  @spec plan(Issue.t()) :: {:ok, RemediationPlan.t()} | {:error, String.t()}
  def plan(%Issue{issue_type: :stale_resource} = issue) do
    Logger.debug("Planning remediation for stale resource (issue_id: #{issue.id}, subject: #{issue.subject})")

    {api_version_kind, namespace, name} = destructure_params(issue)

    {:ok,
     RemediationPlan.delete_resource(
       api_version_kind,
       namespace,
       name
     )}
  end

  def plan(%Issue{} = issue) do
    # This is mostly a hack to make dialyzer happy
    Logger.error("Planning remediation for unknown issue type (issue_id: #{issue.id}, subject: #{issue.subject})")
    {:error, "Unknown issue type"}
  end

  @doc """
  Verify that the remediation was successful.

  For stale resource deletion, this checks that the resource no longer exists in the cluster.
  """
  @spec verify(Issue.t()) :: {:ok, :resolved} | {:ok, :pending} | {:error, String.t()}
  def verify(%Issue{issue_type: :stale_resource} = issue) do
    Logger.debug("Verifying stale resource deletion success (issue_id: #{issue.id})")

    {api_version_kind, namespace, name} = destructure_params(issue)

    case KubeState.get(api_version_kind, namespace, name) do
      {:ok, _resource} ->
        {:ok, :pending}

      :missing ->
        {:ok, :resolved}
    end
  end

  def verify(%Issue{} = issue) do
    # This is mostly a hack to make dialyzer happy
    Logger.error("Verifying remediation for unknown issue type (issue_id: #{issue.id}, subject: #{issue.subject})")
    {:error, "Unknown issue type"}
  end

  defp destructure_params(%Issue{trigger_params: params}) do
    api_version_kind =
      params
      |> Map.get("api_version_kind", Map.get(params, :api_version_kind))
      |> String.to_existing_atom()

    namespace = Map.get(params, "namespace", Map.get(params, :namespace))
    name = Map.get(params, "name", Map.get(params, :name))

    {api_version_kind, namespace, name}
  end
end
