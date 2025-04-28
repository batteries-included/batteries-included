defmodule ControlServerWeb.Containers.EnvValueTableTest do
  use Heyya.SnapshotCase

  import ControlServerWeb.Containers.EnvValueTable

  alias CommonCore.Containers.EnvValue

  describe "env_var_table" do
    component_snapshot_test "renders env_var_table with no env values" do
      assigns = %{}

      ~H"""
      <.env_var_table id="test-env-var-table" env_values={[]} />
      """
    end

    component_snapshot_test "renders env_var_table with env values" do
      assigns = %{
        env_values: [
          EnvValue.new!(name: "TEST_ENV", source_type: :value, value: "test_value"),
          EnvValue.new!(name: "TEST_ENV_2", source_type: :config, source_name: "test_config", source_key: "test_key")
        ]
      }

      ~H"""
      <.env_var_table id="test-env-var-table" env_values={@env_values} />
      """
    end
  end
end
