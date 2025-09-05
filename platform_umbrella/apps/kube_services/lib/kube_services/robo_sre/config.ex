defmodule KubeServices.RoboSRE.Config do
  @moduledoc """
  Configuration for RoboSRE analyzers and handlers.

  This module defines the mappings between issue types and their corresponding
  analyzers and handlers. It follows the pattern described in the RoboSRE documentation.
  """

  alias KubeServices.RoboSRE.Analyzers.StaleResourceAnalyzer
  alias KubeServices.RoboSRE.Handlers.StaleResourceHandler

  @doc """
  Get the analyzer mappings for different issue types.

  Each issue type can only have a single type-specific analyzer that must be able 
  to handle all the different ways that triggers can report their issue.

  Returns a map of issue_type => analyzer_module
  """
  @spec analyzer_mappings() :: %{atom() => module()}
  def analyzer_mappings do
    %{
      stale_resource: StaleResourceAnalyzer
      # Future analyzers will be added here:
      # pod_crash: PodCrashAnalyzer,
      # stuck_kubestate: StuckKubeStateAnalyzer
    }
  end

  @doc """
  Get the handler mappings for different issue types.

  Each issue type maps to a list of handlers that can remediate the issue.
  Multiple handlers can be defined for fallback scenarios.

  Returns a map of issue_type => [handler_module]
  """
  @spec handler_mappings() :: %{atom() => [module()]}
  def handler_mappings do
    %{
      stale_resource: [StaleResourceHandler]
      # Future handlers will be added here:
      # stuck_kubestate: [StuckKubeStateHandler]
    }
  end

  @doc """
  Get the analyzer module for a specific issue type.
  """
  @spec get_analyzer(atom()) :: {:ok, module()} | {:error, :not_found}
  def get_analyzer(issue_type) do
    case Map.get(analyzer_mappings(), issue_type) do
      nil -> {:error, :not_found}
      analyzer -> {:ok, analyzer}
    end
  end

  @doc """
  Get the handler modules for a specific issue type.
  """
  @spec get_handlers(atom()) :: {:ok, [module()]} | {:error, :not_found}
  def get_handlers(issue_type) do
    case Map.get(handler_mappings(), issue_type) do
      nil -> {:error, :not_found}
      handlers -> {:ok, handlers}
    end
  end
end
