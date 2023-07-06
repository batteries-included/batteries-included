defmodule WhatsUp.Detector.Site do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sites" do
    field :timeout, :integer
    field :url, :string

    timestamps()
  end

  @doc false
  def changeset(site, attrs) do
    site
    |> cast(attrs, [:url, :timeout])
    |> validate_required([:url, :timeout])
    |> validate_url()
  end

  defp validate_url(changeset) do
    validate_change(changeset, :url, fn _, value ->
      case URI.parse(value) do
        %URI{scheme: nil} ->
          [uri: "Must have a schema like https or http"]

        %URI{host: nil} ->
          [uri: "Host must be a part of the uri."]

        %URI{host: ""} ->
          [uri: "Host must be a part of the uri."]

        _ ->
          []
      end
    end)
  end
end
