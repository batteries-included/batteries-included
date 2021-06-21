defmodule KubeUsage.Factory do
  @moduledoc """

  Factory for kube_usage ecto.
  """

  # with Ecto
  use ExMachina.Ecto, repo: KubeUsage.Repo
end
