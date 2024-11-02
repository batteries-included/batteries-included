defmodule CommonCore.Resources.ResourceGeneratorTest do
  use ExUnit.Case

  import CommonCore.Factory

  alias CommonCore.Resources.ExampleGenerator

  describe "CommonCore.Resources.ResourceGenerator" do
    test "Test the generator works" do
      result = ExampleGenerator.materialize(%{config: %{}}, build(:state_summary))
      assert %{"/service_account/main" => _} = result
    end

    test "The multi resource with a list works" do
      result = ExampleGenerator.materialize(%{config: %{}}, build(:state_summary))

      assert %{
               "/service_account/multi_list_0" => _,
               "/service_account/multi_list_1" => _,
               "/service_account/multi_list_2" => _,
               "/service_account/multi_list_3" => _,
               "/service_account/multi_list_4" => _,
               "/service_account/multi_list_5" => _,
               "/service_account/multi_list_6" => _,
               "/service_account/multi_list_7" => _,
               "/service_account/multi_list_8" => _,
               "/service_account/multi_list_9" => _
             } = result
    end

    test "The multi resource with a map" do
      result = ExampleGenerator.materialize(%{config: %{}}, build(:state_summary))

      assert %{
               "/map_0/service_account/map_0" => _,
               "/map_1/service_account/map_1" => _
             } = result
    end
  end
end
