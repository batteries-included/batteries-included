defmodule CommonCore.Util.Tesla do
  @moduledoc false

  def to_result({:ok, %{status: 200, body: body}}, nil) do
    {:ok, body}
  end

  def to_result({:ok, %{status_code: 200, body: body}}, nil) do
    {:ok, body}
  end

  def to_result({:ok, %{status: 200, body: body}}, mapper) when is_list(body) do
    {:ok, Enum.map(body, mapper)}
  end

  def to_result({:ok, %{status_code: 200, body: body}}, mapper) when is_list(body) do
    {:ok, Enum.map(body, mapper)}
  end

  def to_result({:ok, %{status: 200, body: body}}, mapper) do
    {:ok, mapper.(body)}
  end

  def to_result({:ok, %{status_code: 200, body: body}}, mapper) do
    {:ok, mapper.(body)}
  end

  def to_result({:ok, %{status: 204}}, _mapper) do
    {:ok, :success}
  end

  def to_result({:ok, %{status_code: 204}}, _mapper) do
    {:ok, :success}
  end

  def to_result({:ok, %{status: 201, headers: headers}}, nil) do
    {:ok, find_location(headers)}
  end

  def to_result({:ok, %{status_code: 201, headers: headers}}, nil) do
    {:ok, find_location(headers)}
  end

  def to_result({:ok, %{status: 409, body: %{"error" => _error}}}, _mapper) do
    {:error, :error_already_exists}
  end

  def to_result({:ok, %{status_code: 409, body: %{"error" => _error}}}, _mapper) do
    {:error, :error_already_exists}
  end

  def to_result({:ok, %{body: %{"error" => error}}}, _mapper) do
    {:error, error}
  end

  def to_result({:ok, %{body: %{"errorMessage" => error}}}, _mapper) do
    {:error, error}
  end

  def to_result({:error, error}, _mapper), do: {:error, error}

  def to_result(_error, _mapper) do
    {:error, :unknown_keycloak_error}
  end

  ## Helpers
  defp find_location(headers) do
    headers
    |> Enum.filter(fn {key, _} -> key == "location" end)
    |> Enum.map(fn {_, value} -> value end)
    |> List.first()
  end
end
