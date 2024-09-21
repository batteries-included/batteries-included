defmodule Mix.Tasks.Jwk.Pem.Json do
  @shortdoc "Output a JSON key from a jwk PEM file."
  @moduledoc """
  Output a JSON key from a jwk PEM file.
  """

  use Mix.Task

  require Logger

  def run(paths) do
    Enum.each(paths, &print/1)
  end

  defp print(path) do
    path |> File.read!() |> JOSE.JWK.from_pem() |> JOSE.JWK.to_binary() |> elem(1) |> IO.puts()
  end
end
