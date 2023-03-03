defmodule CommonCore.DockerIps do
  def get_kind_ips do
    # Get all the subnets for kind.
    # However we only want ipv4 so reject anything that's ipv6
    Enum.reject(get_network_subnets("kind"), fn sub -> String.contains?(sub, ":") end)
  end

  def get_network_subnets(network \\ "kind") do
    try do
      case System.cmd("docker", ["network", "inspect", network]) do
        {result_string, 0} ->
          parse_subnets(result_string)

        _ ->
          []
      end
    rescue
      _ -> []
    end
  end

  defp parse_subnets(value) do
    value
    |> Jason.decode!()
    |> Enum.at(0)
    |> get_in(~w|IPAM Config|)
    |> Enum.map(fn config -> Map.get(config, "Subnet") end)
  end
end
