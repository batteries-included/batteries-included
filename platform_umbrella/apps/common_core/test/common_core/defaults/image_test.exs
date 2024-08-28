defmodule CommonCore.Defaults.ImageTest do
  use ExUnit.Case

  alias CommonCore.Defaults.Image

  @valid_image_attrs %{name: "bi/image", tags: ~w(a b c), default_tag: "a"}

  describe "CommonCore.Defaults.Image" do
    test "valid image can be new'd" do
      assert {:ok, image} = Image.new(@valid_image_attrs)
      assert image.name == "bi/image"
      assert image.tags == ~w(a b c)
      assert image.default_tag == "a"
    end

    test "name is a required field" do
      assert {:error, _} = Image.new(Map.delete(@valid_image_attrs, :name))
    end

    test "tags is a required field" do
      assert {:error, _} = Image.new(Map.delete(@valid_image_attrs, :tags))
    end

    test "default_tag is a required field" do
      assert {:error, _} = Image.new(Map.delete(@valid_image_attrs, :default_tag))
    end

    test "default_tag must be in tags" do
      assert {:error, _} = Image.new(%{@valid_image_attrs | default_tag: "not in tags"})
    end
  end
end
