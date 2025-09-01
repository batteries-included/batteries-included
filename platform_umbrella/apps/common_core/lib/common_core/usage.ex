defmodule CommonCore.Usage do
  @moduledoc """
  Ecto enum for installation usage types.
  """

  use CommonCore.Ecto.Enum,
    internal_dev: "internal_dev",
    internal_int_test: "internal_int_test",
    internal_prod: "internal_prod",
    development: "development",
    production: "production",
    secure_production: "secure_production",
    kitchen_sink: "kitchen_sink"

  alias CommonCore.Accounts.AdminTeams

  @spec usages() :: [{String.t(), atom()}]
  def usages do
    # Return a list of {display_label, atom_value} to match the previous
    # `Options.usages()` shape which callers passed to select helpers.
    Enum.map(__enum_map__(), fn {atom, _val} ->
      {atom |> Atom.to_string() |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1), atom}
    end)
  end

  @spec options(any()) :: [{String.t(), atom()}]
  def options(role) do
    usages = usages()

    if AdminTeams.batteries_included_admin?(role) do
      usages
    else
      Enum.reject(usages, fn {key, _} -> String.starts_with?(key, "Internal") end)
    end
  end

  @spec label(t()) :: String.t()
  def label(value) when is_atom(value),
    do:
      value |> Atom.to_string() |> String.replace("_", " ") |> String.split() |> Enum.map_join(" ", &String.capitalize/1)

  def label(other), do: to_string(other)
end
