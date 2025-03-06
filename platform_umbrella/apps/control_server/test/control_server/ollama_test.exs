defmodule ControlServer.OllamaTest do
  use ControlServer.DataCase

  alias ControlServer.Ollama

  describe "model_instances" do
    import ControlServer.OllamaFixtures

    alias CommonCore.Ollama.ModelInstance

    @invalid_attrs %{
      name: "",
      model: nil,
      num_instances: -1,
      cpu_requested: -1,
      cpu_limits: nil,
      memory_requested: nil,
      memory_limits: nil,
      gpu_count: nil
    }

    @valid_attrs %{
      name: "somename",
      model: "llama3.1:8b",
      num_instances: 2,
      gpu_count: 0,
      node_type: :default,
      cpu_requested: 500,
      memory_requested: 512_000_000,
      memory_limits: 512_000_000
    }

    test "list_model_instances/0 returns all model_instances" do
      model_instance = model_instance_fixture()
      assert Enum.map(Ollama.list_model_instances(), & &1.id) == [model_instance.id]
    end

    test "get_model_instance!/1 returns the model_instance with given id" do
      model_instance = model_instance_fixture()
      assert Ollama.get_model_instance!(model_instance.id).name == model_instance.name
      assert Ollama.get_model_instance!(model_instance.id).id == model_instance.id
    end

    test "create_model_instance/1 with valid data creates a model_instance" do
      assert {:ok, %ModelInstance{} = model_instance} = Ollama.create_model_instance(@valid_attrs)
      assert model_instance.name == "somename"
      assert model_instance.model == "llama3.1:8b"

      assert {:ok, %ModelInstance{}} =
               Ollama.create_model_instance(%{@valid_attrs | node_type: :nvidia_a10, gpu_count: 1})
    end

    test "create_model_instance/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ollama.create_model_instance(@invalid_attrs)

      assert {:error, %Ecto.Changeset{errors: [node_type: _]}} =
               Ollama.create_model_instance(%{@valid_attrs | node_type: :nvidia_a10})

      assert {:error, %Ecto.Changeset{errors: [gpu_count: _]}} =
               Ollama.create_model_instance(%{@valid_attrs | gpu_count: 1})
    end

    test "update_model_instance/2 with valid data updates the model_instance" do
      model_instance = model_instance_fixture()
      update_attrs = %{name: "newname", model: "llama3.2:3b"}

      assert {:ok, %ModelInstance{} = model_instance} = Ollama.update_model_instance(model_instance, update_attrs)

      assert model_instance.name == "newname"
      assert model_instance.model == "llama3.2:3b"
    end

    test "update_model_instance/2 with invalid data returns error changeset" do
      model_instance = model_instance_fixture()
      assert {:error, %Ecto.Changeset{}} = Ollama.update_model_instance(model_instance, @invalid_attrs)
      assert model_instance.id == Ollama.get_model_instance!(model_instance.id).id
    end

    test "delete_model_instance/1 deletes the model_instance" do
      model_instance = model_instance_fixture()
      assert {:ok, %ModelInstance{}} = Ollama.delete_model_instance(model_instance)
      assert_raise Ecto.NoResultsError, fn -> Ollama.get_model_instance!(model_instance.id) end
    end

    test "change_model_instance/1 returns a model_instance changeset" do
      model_instance = model_instance_fixture()
      assert %Ecto.Changeset{} = Ollama.change_model_instance(model_instance)
    end
  end
end
