defmodule CommonCore.K8s.Behaviour do
  @moduledoc """
  Behaviour for a K8s client wrapper so it can be mocked in tests with Mox.

  This mirrors the public API of `K8s.Client` used by applications.
  """
  alias K8s.Client.Provider

  @type path_params :: K8s.Client.path_params()

  @callback put_conn(K8s.Operation.t(), K8s.Conn.t()) :: K8s.Operation.t()

  @callback run(K8s.Operation.t()) :: K8s.Client.Runner.Base.result_t()
  @callback run(K8s.Conn.t(), K8s.Operation.t()) :: K8s.Client.Runner.Base.result_t()
  @callback run(K8s.Operation.t(), keyword()) :: K8s.Client.Runner.Base.result_t()
  @callback run(K8s.Conn.t(), K8s.Operation.t(), keyword()) :: K8s.Client.Runner.Base.result_t()

  @callback async(K8s.Conn.t(), [K8s.Operation.t()]) :: [K8s.Client.Runner.Base.result_t()]
  @callback async(K8s.Conn.t(), [K8s.Operation.t()], keyword()) :: [K8s.Client.Runner.Base.result_t()]
  @callback parallel(K8s.Conn.t(), [K8s.Operation.t()], keyword()) :: [K8s.Client.Runner.Base.result_t()]

  @callback wait_until(K8s.Operation.t(), keyword()) :: {:ok, :deleted} | {:ok, map()} | {:error, any()}
  @callback wait_until(K8s.Conn.t(), K8s.Operation.t(), keyword()) :: {:ok, :deleted} | {:ok, map()} | {:error, any()}

  @callback stream(K8s.Operation.t()) :: {:ok, Enumerable.t()} | Provider.stream_response_t()
  @callback stream(K8s.Conn.t(), K8s.Operation.t()) :: {:ok, Enumerable.t()} | Provider.stream_response_t()
  @callback stream(K8s.Conn.t(), K8s.Operation.t(), keyword()) :: Provider.stream_response_t() | {:ok, Enumerable.t()}

  @callback stream_to(K8s.Operation.t(), pid()) :: Provider.stream_to_response_t()
  @callback stream_to(K8s.Conn.t(), K8s.Operation.t(), pid()) :: Provider.stream_to_response_t()
  @callback stream_to(K8s.Conn.t(), K8s.Operation.t(), keyword(), pid()) :: Provider.stream_to_response_t()

  @callback apply(map()) :: K8s.Operation.t()
  @callback apply(map(), keyword()) :: K8s.Operation.t()
  @callback apply(binary(), K8s.Operation.name_t(), path_params() | nil, map(), keyword()) :: K8s.Operation.t()

  @callback get(map()) :: K8s.Operation.t()
  @callback get(binary(), K8s.Operation.name_t(), path_params() | nil) :: K8s.Operation.t()

  @callback list(binary(), K8s.Operation.name_t(), path_params() | nil) :: K8s.Operation.t()

  @callback watch(binary(), K8s.Operation.name_t(), path_params() | nil) :: K8s.Operation.t()

  @callback create(map()) :: K8s.Operation.t()
  @callback create(binary(), K8s.Operation.name_t(), path_params(), map()) :: K8s.Operation.t()
  @callback create(map(), map()) :: K8s.Operation.t()

  @callback patch(map()) :: K8s.Operation.t()
  @callback patch(map(), K8s.Operation.patch_type() | map()) :: K8s.Operation.t()
  @callback patch(binary(), K8s.Operation.name_t(), path_params(), map(), K8s.Operation.patch_type()) :: K8s.Operation.t()
  @callback patch(map(), map(), K8s.Operation.patch_type()) :: K8s.Operation.t()

  @callback update(map()) :: K8s.Operation.t()
  @callback update(binary(), K8s.Operation.name_t(), path_params(), map()) :: K8s.Operation.t()
  @callback update(map(), map()) :: K8s.Operation.t()

  @callback delete(map()) :: K8s.Operation.t()
  @callback delete(binary(), K8s.Operation.name_t(), path_params()) :: K8s.Operation.t()

  @callback delete_all(binary(), binary() | atom()) :: K8s.Operation.t()
  @callback delete_all(binary(), binary() | atom(), namespace: binary()) :: K8s.Operation.t()

  @callback connect(binary(), binary() | atom(), [namespace: binary(), name: binary()], keyword()) :: K8s.Operation.t()
end
