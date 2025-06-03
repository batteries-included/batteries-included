defmodule CommonCore.Git do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @git_hash unquote(__MODULE__).current_git_hash()

      def __mix_recompile__?, do: unquote(__MODULE__).current_git_hash() != @git_hash
    end
  end

  def current_git_hash do
    case System.cmd("git", ["describe", "--match=\"badtagthatnevermatches\"", "--always", "--dirty"],
           stderr_to_stdout: true,
           env: []
         ) do
      {msg, 0} ->
        String.trim(msg)

      _ ->
        ""
    end
  end
end
