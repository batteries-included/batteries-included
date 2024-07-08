defmodule CommonCore.Version do
  @moduledoc false

  @hash "git"
        |> System.cmd(["describe", "--match=\"badtagthatnevermatches\"", "--always", "--dirty"])
        |> elem(0)
        |> String.trim()
  @version Mix.Project.config()[:version]

  def version, do: @version
  def hash, do: @hash
end
