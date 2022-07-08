defmodule KubeExt.MapsettingsTest do
  use ExUnit.Case
  doctest KubeExt.MapSettings

  defmodule TestSettings do
    import KubeExt.MapSettings

    setting(:my_image, :image, "test_image:v0.1.1")
    setting_fn(:id, :id, &System.unique_integer/0)
  end

  describe "KubeExt.Mapsettings" do
    test "TestSettings.my_image/1 uses the default" do
      assert "test_image:v0.1.1" == TestSettings.my_image(%{})
    end

    test "TestSettings.my_image/1 can get the atom value" do
      assert "my_images:v0.2.1" == TestSettings.my_image(%{image: "my_images:v0.2.1"})
    end

    test "TestSettings.my_image/1 can get the string value" do
      assert "test_string:v0.3.1" == TestSettings.my_image(%{"image" => "test_string:v0.3.1"})
    end

    test "Uses the function in TestSettings.id/1" do
      assert TestSettings.id(%{}) != TestSettings.id(%{})
    end
  end
end
