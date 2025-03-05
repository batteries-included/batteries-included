defmodule ControlServer.OllamaFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.Ollama` context.
  """

  @doc """
  Generate a model_instance.
  """
  def model_instance_fixture(attrs \\ %{}) do
    {:ok, model_instance} =
      attrs
      |> Enum.into(%{
        model: "llama3.1:8b",
        name: "somename",
        num_replicas: 2,
        gpu_count: 0,
        size: "tiny"
      })
      |> ControlServer.Ollama.create_model_instance()

    model_instance
  end
end
