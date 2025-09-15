defmodule KubeServices.RoboSRE.Handler do
  @moduledoc """
  Behaviour for handling RoboSRE issues.

  ## Preflight

  The `preflight/1` function is called before executing any actions. It checks if the planned action can be performed.
  It returns:
  - `{:ok, :ready}` if the action can be performed
  - `{:ok, :skip}` if the action should be skipped (e.g., resource already deleted)
  - `{:error, reason}` if there was an error preventing the action from being performed

  ## Plan
  The `plan/1` function generates a remediation plan for the given issue. It returns:
  - `{:ok, %RemediationPlan{}}` if a plan was successfully created
  - `{:error, reason}` if there was an error creating the plan

  ## Verify
  The `verify/1` function checks if the remediation was successful. It returns:
  - `{:ok, :resolved}` if the issue has been resolved
  - `{:ok, :pending}` if the issue is still pending resolution. Note that this can return pending after the issues's timeout has passed; in such cases the issue worker will treat that as a failure.
  - `{:error, reason}` if there was an error during verification
  """
  alias CommonCore.RoboSRE.Issue

  @callback preflight(issue :: Issue.t()) :: {:ok, :ready | :skip} | {:error, any()}
  @callback plan(issue :: Issue.t()) :: {:ok, CommonCore.RoboSRE.RemediationPlan.t()} | {:error, any()}
  @callback verify(issue :: Issue.t()) :: {:ok, :resolved | :pending} | {:error, any()}
end
