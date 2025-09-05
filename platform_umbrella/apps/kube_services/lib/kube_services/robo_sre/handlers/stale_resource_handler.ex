defmodule KubeServices.RoboSRE.Handlers.StaleResourceHandler do
  @moduledoc """
  Handler for remediating stale resource issues.

  This handler:
  1. Deletes the stale resource from the cluster
  2. Stores the resource in the deleted resource table for potential recovery
  3. Monitors the deletion to ensure it was successful
  """

  use TypedStruct

  alias CommonCore.RoboSRE.Issue
  alias KubeServices.ResourceDeleter

  require Logger

  typedstruct module: RemediationPlan do
    field :actions, list(map()), default: []
    field :success_check_delay_ms, integer(), default: 30_000
    field :retry_delay_ms, integer(), default: 60_000
    field :max_retries, integer(), default: 3
  end

  @doc """
  Create a remediation plan for a stale resource issue.

  The plan includes:
  - Delete action with the resource details
  - Timing for success verification
  - Retry configuration
  """
  @spec plan_remediation(Issue.t(), map()) :: {:ok, RemediationPlan.t()} | {:error, String.t()}
  def plan_remediation(%Issue{} = issue, context) do
    Logger.info("Planning remediation for stale resource (issue_id: #{issue.id}, subject: #{issue.subject})")

    case extract_resource_details(context) do
      {:ok, resource_details} ->
        actions = [
          %{
            type: :delete_resource,
            resource: resource_details,
            description: "Delete stale resource #{context["name"]}"
          }
        ]

        plan = %RemediationPlan{
          actions: actions,
          success_check_delay_ms: 30_000,
          retry_delay_ms: 60_000,
          max_retries: 3
        }

        {:ok, plan}

      {:error, reason} ->
        Logger.error("Failed to plan remediation for stale resource (issue_id: #{issue.id}, reason: #{reason})")
        {:error, reason}
    end
  end

  @doc """
  Execute a single remediation action.
  """
  @spec execute_action(map(), Issue.t()) :: {:ok, map()} | {:error, String.t()}
  def execute_action(%{type: :delete_resource, resource: resource_details} = action, %Issue{} = issue) do
    Logger.info(
      "Executing delete action for stale resource (issue_id: #{issue.id}, resource: #{inspect(resource_details["summary"])})"
    )

    # Reconstruct the resource for deletion
    resource = reconstruct_resource(resource_details)

    case ResourceDeleter.delete(resource) do
      {:ok, result} ->
        Logger.info("Successfully deleted stale resource (issue_id: #{issue.id}, result: #{inspect(result)})")

        {:ok,
         %{
           action: action,
           result: result,
           completed_at: DateTime.to_iso8601(DateTime.utc_now())
         }}

      {:error, reason} ->
        Logger.error("Failed to delete stale resource (issue_id: #{issue.id}, reason: #{inspect(reason)})")
        {:error, "Delete failed: #{inspect(reason)}"}
    end
  end

  def execute_action(%{type: unknown_type}, %Issue{} = issue) do
    Logger.error("Unknown action type (issue_id: #{issue.id}, type: #{unknown_type})")
    {:error, "Unknown action type: #{unknown_type}"}
  end

  @doc """
  Verify that the remediation was successful.

  For stale resource deletion, this checks that the resource no longer exists in the cluster.
  """
  @spec verify_success(Issue.t(), map()) :: {:ok, :resolved} | {:ok, :pending} | {:error, String.t()}
  def verify_success(%Issue{} = issue, context) do
    Logger.debug("Verifying stale resource deletion success (issue_id: #{issue.id})")

    with {:ok, avk} <- get_api_version_kind(context),
         {:ok, {namespace, name}} <- get_resource_identity(context) do
      case CommonCore.ApiVersionKind.resource_type(avk) do
        nil ->
          Logger.warning("Unknown resource type for verification (issue_id: #{issue.id})")
          {:ok, :resolved}

        resource_type ->
          case KubeServices.KubeState.get(resource_type, namespace, name) do
            :missing ->
              Logger.info(
                "Stale resource successfully deleted (issue_id: #{issue.id}, namespace: #{namespace}, name: #{name})"
              )

              {:ok, :resolved}

            {:ok, _resource} ->
              Logger.debug("Stale resource still exists, deletion may be in progress (issue_id: #{issue.id})")
              {:ok, :pending}
          end
      end
    else
      {:error, reason} ->
        Logger.error("Error verifying stale resource deletion (issue_id: #{issue.id}, reason: #{reason})")
        {:error, "Verification failed: #{reason}"}
    end
  end

  # Extract resource details needed for deletion from analysis context
  defp extract_resource_details(context) do
    required_fields = ["namespace", "name", "api_version_kind", "resource_summary"]

    if Enum.all?(required_fields, &Map.has_key?(context, &1)) do
      {:ok, context}
    else
      missing = Enum.reject(required_fields, &Map.has_key?(context, &1))
      {:error, "Missing required context fields: #{Enum.join(missing, ", ")}"}
    end
  end

  # Reconstruct a resource map from stored details for deletion
  defp reconstruct_resource(resource_details) do
    avk = resource_details["api_version_kind"]
    summary = resource_details["resource_summary"]

    # Build minimal resource map needed for deletion
    Map.merge(
      %{
        "apiVersion" => avk["api_version"],
        "kind" => avk["kind"],
        "metadata" => %{"name" => resource_details["name"], "namespace" => resource_details["namespace"]}
      },
      Map.get(summary, "extra_metadata", %{})
    )
  end

  # Get API version kind from context
  defp get_api_version_kind(context) do
    case Map.get(context, "api_version_kind") do
      nil -> {:error, "Missing api_version_kind"}
      avk -> {:ok, avk}
    end
  end

  # Get resource namespace and name from context
  defp get_resource_identity(context) do
    namespace = Map.get(context, "namespace")
    name = Map.get(context, "name")

    if name do
      {:ok, {namespace, name}}
    else
      {:error, "Missing resource name"}
    end
  end
end
