defmodule CommonCore.StateSummary.AccessSpec do
  @moduledoc false
  use TypedStruct

  alias CommonCore.StateSummary

  @derive Jason.Encoder
  typedstruct do
    field :hostname, :string
    field :ssl, :boolean

    # TODO: Add initial username and password fields
  end

  def new(%StateSummary{} = state_summary) do
    hostname = StateSummary.Hosts.control_host(state_summary)

    if valid_host?(hostname) do
      ssl = StateSummary.SSL.ssl_enabled?(state_summary)
      {:ok, struct!(__MODULE__, hostname: hostname, ssl: ssl)}
    else
      {:error, "Invalid hostname"}
    end
  end

  def to_data(%__MODULE__{} = spec) do
    %{
      "hostname" => spec.hostname,
      "ssl" => to_string(spec.ssl)
    }
  end

  defp valid_host?(host) do
    host != nil and
      String.length(host) > 0 and
      !String.contains?(host, "..ip.batteriesincl.com") and
      valid_uri?(host)
  end

  # assume for now that, if it's parseable, that's good enough
  defp valid_uri?(host) do
    case URI.new(host) do
      {:ok, _uri} -> true
      _ -> false
    end
  end
end
