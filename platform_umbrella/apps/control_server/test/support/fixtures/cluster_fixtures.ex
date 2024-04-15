defmodule ControlServer.ClusterFixtures do
  @moduledoc false
  def cluster_fixture(override_attrs \\ %{}) do
    {:ok, cluster} =
      override_attrs
      |> Enum.into(%{
        name: MnemonicSlugs.generate_slug(4),
        num_instances: 3,
        virtual_size: "small",
        type: :standard,
        users: [%{username: "userone", roles: ["superuser"]}],
        database: %{name: "maindata", owner: "userone"}
      })
      |> ControlServer.Postgres.create_cluster()

    Map.put(cluster, :virtual_size, nil)
  end
end
