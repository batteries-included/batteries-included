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

  @spec compare(String.t(), String.t()) ::
          {:ok, :equal} | {:ok, :greater} | {:ok, :lesser} | {:error, :incomparable}
  def compare(a, b) do
    inner_compare(parse(a), parse(b))
  end

  # Parse a dotted version string into a list of integers
  @spec parse(String.t()) :: [integer() | nil]
  defp parse(str) do
    str
    |> String.split(".")
    |> Enum.map(&parse_integer/1)
  end

  # This parses the integer part of dotted version strings
  # The last part can include a dash and a hash or other suffix
  # This function will only parse the integer part
  @spec parse_integer(String.t()) :: integer() | nil
  defp parse_integer(str) do
    result =
      str
      |> String.split("-")
      |> List.first()
      |> Integer.parse()

    case result do
      {int, _} ->
        int

      :error ->
        nil
    end
  end

  @spec inner_compare([integer() | nil], [integer() | nil]) ::
          {:ok, :equal} | {:ok, :greater} | {:ok, :lesser} | {:error, :incomparable}
  defp inner_compare([], []), do: {:ok, :equal}
  defp inner_compare([a | _], [b | _]) when is_nil(a) or is_nil(b), do: {:error, :incomparable}
  defp inner_compare([a | as], [b | bs]) when a == b, do: inner_compare(as, bs)
  defp inner_compare([a | _], [b | _]) when a > b, do: {:ok, :greater}
  defp inner_compare([a | _], [b | _]) when a < b, do: {:ok, :lesser}
  defp inner_compare(_, _), do: {:error, :incomparable}
end
