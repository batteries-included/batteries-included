defmodule HomeBase.ControlServerClustersTest do
  use HomeBase.DataCase

  alias HomeBase.ControlServerClusters

  describe "installations" do
    alias HomeBase.ControlServerClusters.Installation

    import HomeBase.ControlServerClustersFixtures

    @invalid_attrs %{bootstrap_config: nil, slug: nil}

    test "list_installations/0 returns all installations" do
      installation = installation_fixture()
      assert ControlServerClusters.list_installations() == [installation]
    end

    test "get_installation!/1 returns the installation with given id" do
      installation = installation_fixture()
      assert ControlServerClusters.get_installation!(installation.id) == installation
    end

    test "create_installation/1 with valid data creates a installation" do
      valid_attrs = %{slug: "some slug"}

      assert {:ok, %Installation{} = installation} =
               ControlServerClusters.create_installation(valid_attrs)

      assert installation.slug == "some slug"
    end

    test "create_installation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               ControlServerClusters.create_installation(@invalid_attrs)
    end

    test "update_installation/2 with valid data updates the installation" do
      installation = installation_fixture()
      update_attrs = %{slug: "some updated slug"}

      assert {:ok, %Installation{} = installation} =
               ControlServerClusters.update_installation(installation, update_attrs)

      assert installation.slug == "some updated slug"
    end

    test "update_installation/2 with invalid data returns error changeset" do
      installation = installation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               ControlServerClusters.update_installation(installation, @invalid_attrs)

      assert installation == ControlServerClusters.get_installation!(installation.id)
    end

    test "delete_installation/1 deletes the installation" do
      installation = installation_fixture()
      assert {:ok, %Installation{}} = ControlServerClusters.delete_installation(installation)

      assert_raise Ecto.NoResultsError, fn ->
        ControlServerClusters.get_installation!(installation.id)
      end
    end

    test "change_installation/1 returns a installation changeset" do
      installation = installation_fixture()
      assert %Ecto.Changeset{} = ControlServerClusters.change_installation(installation)
    end
  end
end
