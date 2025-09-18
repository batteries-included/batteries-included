defmodule CommonCore.K8s.Client do
  @moduledoc """
  This is a wrapper on the K8s.Client module to allow for easier mocking in tests.
  """
  @behaviour CommonCore.K8s.Behaviour

  # Delegate all public K8s.Client functions so production code calls through
  # the wrapper, which can be mocked in tests using Mox.
  defdelegate put_conn(operation, conn), to: K8s.Client

  defdelegate run(operation), to: K8s.Client
  defdelegate run(conn, operation), to: K8s.Client
  defdelegate run(conn, operation, http_opts), to: K8s.Client

  defdelegate async(conn, operations), to: K8s.Client
  defdelegate async(conn, operations, http_opts), to: K8s.Client
  defdelegate parallel(conn, operations, http_opts), to: K8s.Client

  defdelegate wait_until(operation, wait_opts), to: K8s.Client
  defdelegate wait_until(conn, operation, wait_opts), to: K8s.Client

  defdelegate stream(operation), to: K8s.Client
  defdelegate stream(conn, operation), to: K8s.Client
  defdelegate stream(conn, operation, http_opts), to: K8s.Client

  defdelegate stream_to(operation, stream_to), to: K8s.Client
  defdelegate stream_to(conn, operation, stream_to), to: K8s.Client
  defdelegate stream_to(conn, operation, http_opts, stream_to), to: K8s.Client

  defdelegate apply(resource, mgmt_params \\ []), to: K8s.Client
  defdelegate apply(api_version, kind, path_params, subresource, mgmt_params \\ []), to: K8s.Client

  defdelegate get(resource), to: K8s.Client
  defdelegate get(api_version, kind, path_params \\ []), to: K8s.Client

  defdelegate list(api_version, kind, path_params \\ []), to: K8s.Client

  defdelegate watch(api_version, kind, path_params \\ []), to: K8s.Client

  defdelegate create(resource), to: K8s.Client
  defdelegate create(api_version, kind, path_params, subresource), to: K8s.Client
  defdelegate create(resource, subresource), to: K8s.Client

  defdelegate patch(resource), to: K8s.Client
  defdelegate patch(resource, patch_type_or_resource), to: K8s.Client
  defdelegate patch(api_version, kind, path_params, subresource, patch_type \\ :merge), to: K8s.Client
  defdelegate patch(resource, subresource, patch_type), to: K8s.Client

  defdelegate update(resource), to: K8s.Client
  defdelegate update(api_version, kind, path_params, subresource), to: K8s.Client
  defdelegate update(resource, subresource), to: K8s.Client

  defdelegate delete(resource), to: K8s.Client
  defdelegate delete(api_version, kind, path_params), to: K8s.Client

  defdelegate delete_all(api_version, kind), to: K8s.Client
  defdelegate delete_all(api_version, kind, opts), to: K8s.Client

  defdelegate connect(api_version, kind, path_params, opts \\ []), to: K8s.Client
end
