defmodule Bootstrap.Database do
  @default_pg_cluster %{
    :name => "control",
    :postgres_version => "13",
    :num_instances => 1,
    :size => "1G"
  }

  def control_cluster do
    @default_pg_cluster
  end
end
