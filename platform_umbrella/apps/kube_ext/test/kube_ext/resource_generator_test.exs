defmodule KubeExt.ResourceGeneratorTest do
  use ExUnit.Case

  describe "KubeExt.ResourceGenerator" do
    test "Test the generator works" do
      result = KubeExt.ExampleGenerator.materialize(%{config: %{}}, %{})
      assert %{"/service_account/main" => _} = result
    end
  end
end
