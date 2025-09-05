defmodule KubeServices.RoboSRE.Analyzers.StaleResourceAnalyzer do
  @moduledoc """
  Analyzer for stale resource issues.

  This analyzer validates that resources are indeed stale and gathers context
  needed for remediation, including:
  - Verification that the resource is still stale
  - ApiVersionKind information for deletion
  - Safety checks before recommending deletion
  """

  use TypedStruct

  alias CommonCore.Resources.FieldAccessors
  alias CommonCore.RoboSRE.Issue
  alias KubeServices.Stale

  require Logger

  typedstruct module: AnalysisResult do
    field :valid, boolean(), default: false
    field :context, map(), default: %{}
    field :reason, String.t() | nil
  end

  @doc """
  Analyze a stale resource issue to validate it and gather context for remediation.

  Returns:
  - `{:valid, context}` if the resource is confirmed stale and can be safely removed
  - `{:invalid, reason}` if the resource is no longer stale or cannot be safely removed
  - `{:duplicate, existing_issue_id}` if there's already an active issue for this resource
  """
  @spec analyze(Issue.t()) :: {:valid, map()} | {:invalid, String.t()} | {:duplicate, String.t()}
  def analyze(%Issue{} = issue) do
    Logger.debug("Analyzing stale resource issue (issue_id: #{issue.id}, subject: #{issue.subject})")

    with {:ok, avk} <- extract_api_version_kind(issue),
         {:ok, {namespace, name}} <- parse_subject(issue.subject),
         {:ok, resource} <- find_resource_in_snapshot(avk, namespace, name),
         :ok <- verify_still_stale(resource),
         :ok <- verify_can_delete_safe() do
      context = %{
        "namespace" => namespace,
        "name" => name,
        "api_version_kind" => avk,
        "resource_summary" => FieldAccessors.summary(resource),
        "verified_at" => DateTime.to_iso8601(DateTime.utc_now())
      }

      Logger.info(
        "Stale resource issue validated (issue_id: #{issue.id}, subject: #{issue.subject}, namespace: #{namespace}, name: #{name})"
      )

      {:valid, context}
    else
      {:error, "Resource not found"} ->
        Logger.info("Resource no longer exists, marking issue as invalid (issue_id: #{issue.id})")
        {:invalid, "Resource no longer exists in cluster"}

      {:error, "Resource is no longer stale"} ->
        Logger.info("Resource is no longer stale, marking issue as invalid (issue_id: #{issue.id})")
        {:invalid, "Resource is no longer stale"}

      {:error, "Unsafe to delete resources"} ->
        Logger.warning("Unsafe to delete resources at this time (issue_id: #{issue.id})")
        {:invalid, "Unsafe to delete resources - cluster state may be inconsistent"}

      {:error, reason} ->
        Logger.error("Error analyzing stale resource issue (issue_id: #{issue.id}, reason: #{reason})")
        {:invalid, "Analysis failed: #{inspect(reason)}"}
    end
  end

  # Extract ApiVersionKind from issue trigger params
  defp extract_api_version_kind(%Issue{trigger_params: params}) do
    case Map.get(params, "api_version_kind") do
      nil ->
        {:error, "Missing api_version_kind in trigger params"}

      avk when is_map(avk) ->
        {:ok, avk}

      _ ->
        {:error, "Invalid api_version_kind format"}
    end
  end

  # Parse the subject to extract namespace and name
  defp parse_subject(subject) when is_binary(subject) do
    case String.split(subject, ".", parts: 2) do
      [name] ->
        {:ok, {nil, name}}

      [namespace, name] ->
        {:ok, {namespace, name}}

      _ ->
        {:error, "Invalid subject format"}
    end
  end

  # Find the resource in the current kube snapshot
  defp find_resource_in_snapshot(avk, namespace, name) do
    case CommonCore.ApiVersionKind.resource_type(avk) do
      nil ->
        {:error, "Unknown resource type"}

      resource_type ->
        case KubeServices.KubeState.get(resource_type, namespace, name) do
          :missing ->
            {:error, "Resource not found"}

          {:ok, resource} ->
            {:ok, resource}
        end
    end
  end

  # Verify the resource is still considered stale
  defp verify_still_stale(resource) do
    if Stale.stale?(resource) do
      :ok
    else
      {:error, "Resource is no longer stale"}
    end
  end

  # Verify it's safe to delete resources
  defp verify_can_delete_safe do
    if Stale.can_delete_safe?() do
      :ok
    else
      {:error, "Unsafe to delete resources"}
    end
  end
end
