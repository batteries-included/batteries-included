defmodule CommonCore.ClusterType do
  @moduledoc """
  Ecto enum for cluster types/providers.

  Backed by strings in the database to remain compatible with prior Ecto.Enum usage.
  """

  use CommonCore.Ecto.Enum,
    kind: "kind",
    aws: "aws",
    azure: "azure",
    provided: "provided"

  @doc """
  Returns select options as a list of {display, value} tuples.
  """
  @spec options() :: list({String.t(), t()})
  def options do
    [
      {"Kind", :kind},
      {"AWS", :aws},
      {"Azure", :azure},
      {"Provided", :provided}
    ]
  end

  @doc """
  Human-friendly label for a cluster type atom. Falls back to inspect/1 if unknown.
  """
  @spec label(t()) :: String.t()
  def label(:kind), do: "Kind"
  def label(:aws), do: "AWS"
  def label(:azure), do: "Azure"
  def label(:provided), do: "Provided"
  def label(other), do: to_string(other)
end
