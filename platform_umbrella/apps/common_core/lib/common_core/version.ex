defmodule CommonCore.Version do
  @moduledoc """
  Module for getting the version and hash of the current build.

  This uses git to get the hash and the version from the mix.exs file.
  """

  @args ["describe", "--match=\"badtagthatnevermatches\"", "--always", "--dirty"]

  @hash "git"
        |> System.cmd(@args)
        |> elem(0)
        |> String.trim()

  @version Mix.Project.config()[:version]

  @spec version() :: String.t()
  def version, do: @version

  @spec hash() :: String.t()
  def hash, do: @hash
end
