defmodule CommonCore.PortTest do
  use ExUnit.Case, async: true

  alias CommonCore.Port

  describe "changeset/3" do
    test "creates a valid port with protocol" do
      attrs = %{name: "web", number: 80, protocol: :http}
      changeset = Port.changeset(%Port{}, attrs)

      assert changeset.valid?
      port = Ecto.Changeset.apply_changes(changeset)
      assert port.protocol == :http
    end

    test "creates a valid port with string protocol" do
      attrs = %{name: "web", number: 80, protocol: "tcp"}
      changeset = Port.changeset(%Port{}, attrs)

      assert changeset.valid?
      port = Ecto.Changeset.apply_changes(changeset)
      assert port.protocol == :tcp
    end

    test "validates protocol values" do
      attrs = %{name: "web", number: 80, protocol: :invalid}
      changeset = Port.changeset(%Port{}, attrs)

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :protocol)
    end

    test "sets default protocol to http2" do
      attrs = %{name: "web", number: 80}
      changeset = Port.changeset(%Port{}, attrs)

      assert changeset.valid?
      port = Ecto.Changeset.apply_changes(changeset)
      assert port.protocol == :http2
    end
  end
end
