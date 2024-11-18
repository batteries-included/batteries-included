defmodule CommonCore.Ecto.EnumTest do
  use ExUnit.Case, async: true

  # Create test enum modules for testing
  defmodule StatusEnum do
    @moduledoc false
    use CommonCore.Ecto.Enum,
      active: "IS_ACTIVE",
      inactive: "IS_INACTIVE",
      pending: "IS_PENDING"
  end

  defmodule PriorityEnum do
    @moduledoc false
    use CommonCore.Ecto.Enum,
      low: "low",
      medium: "medium",
      high: "high",
      critical: "critical"
  end

  defmodule EmptyEnum do
    @moduledoc false
    use CommonCore.Ecto.Enum, []
  end

  describe "type/0" do
    test "returns :string as the underlying ecto type" do
      assert StatusEnum.type() == :string
      assert PriorityEnum.type() == :string
      assert EmptyEnum.type() == :string
    end
  end

  describe "cast/1" do
    test "casts valid atom keys to atoms" do
      assert StatusEnum.cast(:active) == {:ok, :active}
      assert StatusEnum.cast(:inactive) == {:ok, :inactive}
      assert StatusEnum.cast(:pending) == {:ok, :pending}
    end

    test "casts valid string values to atoms" do
      assert StatusEnum.cast("IS_ACTIVE") == {:ok, :active}
      assert StatusEnum.cast("IS_INACTIVE") == {:ok, :inactive}
      assert StatusEnum.cast("IS_PENDING") == {:ok, :pending}
    end

    test "returns error for invalid values" do
      assert StatusEnum.cast(:invalid) == :error
      assert StatusEnum.cast("invalid") == :error
      assert StatusEnum.cast(123) == :error
      assert StatusEnum.cast(nil) == :error
    end

    test "works with different enum configurations" do
      assert PriorityEnum.cast(:low) == {:ok, :low}
      assert PriorityEnum.cast("medium") == {:ok, :medium}
      assert PriorityEnum.cast(:invalid) == :error
    end

    test "returns error for empty enum" do
      assert EmptyEnum.cast(:anything) == :error
      assert EmptyEnum.cast("anything") == :error
    end
  end

  describe "dump/1" do
    test "dumps valid atoms to string values" do
      assert StatusEnum.dump(:active) == {:ok, "IS_ACTIVE"}
      assert StatusEnum.dump(:inactive) == {:ok, "IS_INACTIVE"}
      assert StatusEnum.dump(:pending) == {:ok, "IS_PENDING"}
    end

    test "dumps valid string values to themselves" do
      assert StatusEnum.dump("IS_ACTIVE") == {:ok, "IS_ACTIVE"}
      assert StatusEnum.dump("IS_INACTIVE") == {:ok, "IS_INACTIVE"}
      assert StatusEnum.dump("IS_PENDING") == {:ok, "IS_PENDING"}
    end

    test "raises Ecto.ChangeError for invalid values" do
      assert_raise Ecto.ChangeError, ~r/Value `123` is not a valid enum value/, fn ->
        StatusEnum.dump(123)
      end

      assert_raise Ecto.ChangeError, ~r/Value `:invalid` is not a valid enum value/, fn ->
        StatusEnum.dump(:invalid)
      end

      assert_raise Ecto.ChangeError, ~r/Value `"invalid"` is not a valid enum value/, fn ->
        StatusEnum.dump("invalid")
      end
    end

    test "works with different enum configurations" do
      assert PriorityEnum.dump(:low) == {:ok, "low"}
      assert PriorityEnum.dump("high") == {:ok, "high"}
    end
  end

  describe "load/1" do
    test "loads valid string values to atoms" do
      assert StatusEnum.load("IS_ACTIVE") == {:ok, :active}
      assert StatusEnum.load("IS_INACTIVE") == {:ok, :inactive}
      assert StatusEnum.load("IS_PENDING") == {:ok, :pending}
    end

    test "raises Ecto.ChangeError for invalid values" do
      assert_raise Ecto.ChangeError, ~r/Value `123` is not a valid enum/, fn ->
        StatusEnum.load(123)
      end

      assert_raise Ecto.ChangeError, ~r/Value `:invalid` is not a valid enum/, fn ->
        StatusEnum.load(:invalid)
      end

      assert_raise Ecto.ChangeError, ~r/Value `"invalid"` is not a valid enum/, fn ->
        StatusEnum.load("invalid")
      end
    end

    test "works with different enum configurations" do
      assert PriorityEnum.load("medium") == {:ok, :medium}
    end
  end

  describe "equal?/2" do
    test "returns true for equal terms" do
      assert StatusEnum.equal?(:active, :active) == true
      assert StatusEnum.equal?("IS_ACTIVE", "IS_ACTIVE") == true
      assert StatusEnum.equal?(123, 123) == true
    end

    test "returns false for different terms" do
      assert StatusEnum.equal?(:active, :inactive) == false
      assert StatusEnum.equal?("IS_ACTIVE", "IS_INACTIVE") == false
      assert StatusEnum.equal?(:active, "IS_ACTIVE") == false
      assert StatusEnum.equal?(123, 456) == false
    end
  end

  describe "embed_as/1" do
    test "returns :self" do
      assert StatusEnum.embed_as(:any_format) == :self
      assert PriorityEnum.embed_as(:json) == :self
    end
  end

  describe "valid_value?/1" do
    test "returns true for valid string values" do
      assert StatusEnum.valid_value?("IS_ACTIVE") == true
      assert StatusEnum.valid_value?("IS_INACTIVE") == true
      assert StatusEnum.valid_value?("IS_PENDING") == true
    end

    test "returns false for invalid values" do
      assert StatusEnum.valid_value?("invalid") == false
      assert StatusEnum.valid_value?(:active) == false
      assert StatusEnum.valid_value?(123) == false
      assert StatusEnum.valid_value?(nil) == false
    end

    test "works with different enum configurations" do
      assert PriorityEnum.valid_value?("low") == true
      assert PriorityEnum.valid_value?("medium") == true
      assert PriorityEnum.valid_value?("invalid") == false
    end

    test "returns false for empty enum" do
      assert EmptyEnum.valid_value?("anything") == false
      assert EmptyEnum.valid_value?(:anything) == false
    end
  end

  describe "__enum_map__/0" do
    test "returns the enum mapping" do
      expected = %{active: "IS_ACTIVE", inactive: "IS_INACTIVE", pending: "IS_PENDING"}
      assert StatusEnum.__enum_map__() == expected
    end

    test "returns empty map for empty enum" do
      assert EmptyEnum.__enum_map__() == %{}
    end
  end

  describe "__valid_values__/0" do
    test "returns list of valid string values" do
      values = StatusEnum.__valid_values__()
      assert "IS_ACTIVE" in values
      assert "IS_INACTIVE" in values
      assert "IS_PENDING" in values
      assert length(values) == 3
    end

    test "returns empty list for empty enum" do
      assert EmptyEnum.__valid_values__() == []
    end
  end

  describe "Ecto.Type behavior compliance" do
    test "implements all required Ecto.Type callbacks" do
      # Verify that the module properly implements the Ecto.Type behavior
      assert function_exported?(StatusEnum, :type, 0)
      assert function_exported?(StatusEnum, :cast, 1)
      assert function_exported?(StatusEnum, :load, 1)
      assert function_exported?(StatusEnum, :dump, 1)
      assert function_exported?(StatusEnum, :equal?, 2)
      assert function_exported?(StatusEnum, :embed_as, 1)
    end

    test "type/0 returns a valid Ecto primitive type" do
      # The underlying type should be a valid Ecto primitive
      assert StatusEnum.type() in [
               :string,
               :integer,
               :float,
               :boolean,
               :binary,
               :date,
               :time,
               :naive_datetime,
               :utc_datetime
             ]
    end

    test "cast -> dump -> load round trip preserves semantics" do
      # Test the full cycle: cast user input -> dump to DB -> load from DB
      {:ok, casted} = StatusEnum.cast(:active)
      {:ok, dumped} = StatusEnum.dump(casted)
      {:ok, loaded} = StatusEnum.load(dumped)

      assert loaded == :active
      assert StatusEnum.equal?(casted, loaded)
    end

    test "cast -> dump -> load with string input" do
      {:ok, casted} = StatusEnum.cast("IS_INACTIVE")
      {:ok, dumped} = StatusEnum.dump(casted)
      {:ok, loaded} = StatusEnum.load(dumped)

      assert loaded == :inactive
      assert StatusEnum.equal?(casted, loaded)
    end
  end
end
