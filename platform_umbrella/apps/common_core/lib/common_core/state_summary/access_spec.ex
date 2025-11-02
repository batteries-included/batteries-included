defmodule CommonCore.StateSummary.AccessSpec do
  @moduledoc false
  use TypedStruct

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Hosts

  @derive Jason.Encoder
  typedstruct do
    field :hostname, :string
    field :ssl, :boolean

    # TODO: Add initial username and password fields
  end

  def new(%StateSummary{} = state_summary) do
    hostname = Hosts.control_host(state_summary)

    if Hosts.valid_host?(hostname) do
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
end
