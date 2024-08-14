defmodule CommonCore.Installs.Options do
  @moduledoc false

  alias CommonCore.Teams.TeamRole

  @sizes [:tiny, :small, :medium, :large, :xlarge, :huge]
  @providers [Kind: :kind, AWS: :aws, Provided: :provided]
  @usages [
    "Kitchen Sink": :kitchen_sink,
    "Internal Dev": :internal_dev,
    "Internal Test": :internal_int_test,
    "Internal Production": :internal_prod,
    Development: :development,
    Production: :production
  ]

  def usages do
    @usages
  end

  # TODO: Add batteries included team ID that is allowed to create internal installations
  def usage_options(%TeamRole{id: "INTERNAL_TEAM_ID"}), do: @usages

  def usage_options(_role) do
    Enum.reject(@usages, fn {key, _} ->
      key |> Atom.to_string() |> String.starts_with?("Internal")
    end)
  end

  def sizes do
    @sizes
  end

  @spec size_options() :: list(String.t())
  def size_options, do: Enum.map(@sizes, &{&1 |> Atom.to_string() |> String.capitalize(), &1})

  def providers do
    @providers
  end

  def provider_options(:production), do: Enum.filter(@providers, &(elem(&1, 1) != :kind))
  def provider_options(_environment), do: @providers
  def provider_options, do: @providers
end
