defmodule CommonCore.RoboSRE.ActionType do
  @moduledoc """
  Ecto enum for RoboSRE remediation action types.

  Each action type represents a different kind of remediation step that can be executed
  as part of an automated issue resolution.
  """

  use CommonCore.Ecto.Enum,
    delete_resource: "delete_resource",
    restart_kube_state: "restart_kube_state"

  @spec options() :: list({String.t(), t()})
  def options do
    [
      {"Delete Resource", :delete_resource},
      {"Restart Kube State", :restart_kube_state}
    ]
  end

  @spec label(t()) :: String.t()
  def label(:delete_resource), do: "Delete Resource"
  def label(:restart_kube_state), do: "Restart Kube State Process Tree"
  def label(other), do: other |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  @doc """
  Returns whether an action type is considered safe for automated execution.
  """
  @spec safe?(t()) :: boolean()
  def safe?(:delete_resource), do: true

  @doc """
  Validates an action type.
  """
  @spec validate(term()) :: {:ok, t()} | {:error, String.t()}
  def validate(action_type) when action_type == :delete_resource do
    {:ok, action_type}
  end

  def validate(invalid) do
    {:error, "Invalid action type: #{inspect(invalid)}"}
  end
end
