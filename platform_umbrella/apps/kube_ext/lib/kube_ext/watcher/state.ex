defmodule KubeExt.Watcher.State do
  @moduledoc "State of the Watcher"

  alias KubeExt.Watcher.ResponseBuffer

  @type t :: %__MODULE__{
          watcher: Bella.Watcher,
          buffer: ResponseBuffer.t(),
          resource_version: String.t() | nil,
          k8s_watcher_ref: reference() | nil,
          extra: map(),
          client: module(),
          connection: K8s.Conn.t() | nil,
          initial_delay: integer(),
          should_retry_watch: boolean(),
          current_delay: integer(),
          max_delay: integer()
        }

  @default_initial_delay 1000
  @default_watch_timeout 64_000
  @default_should_retry_watch false

  defstruct client: nil,
            connection: nil,
            watcher: nil,
            k8s_watcher_ref: nil,
            buffer: nil,
            resource_version: nil,
            extra: %{},
            watch_timeout: @default_watch_timeout,
            initial_delay: @default_initial_delay,
            should_retry_watch: @default_should_retry_watch,
            current_delay: @default_initial_delay,
            max_delay: 10 * @default_initial_delay

  @spec new(keyword()) :: t()
  def new(opts) do
    conn_func = Keyword.get(opts, :connection_func, fn -> nil end)
    conn = Keyword.get_lazy(opts, :connection, conn_func)
    initial_delay = Keyword.get(opts, :initial_delay, @default_initial_delay)

    %__MODULE__{
      k8s_watcher_ref: nil,
      buffer: ResponseBuffer.new(),
      resource_version: Keyword.get(opts, :resource_version, nil),
      watcher: Keyword.get(opts, :watcher, nil),
      client: Keyword.get(opts, :client, K8s.Client),
      extra: Keyword.get(opts, :extra, %{}),
      initial_delay: initial_delay,
      current_delay: 0,
      should_retry_watch: Keyword.get(opts, :should_retry_watch, @default_should_retry_watch),
      max_delay: Keyword.get(opts, :max_delay, 100 * initial_delay),
      watch_timeout: Keyword.get(opts, :watch_timeout, @default_watch_timeout),
      connection: conn
    }
  end

  @spec next_delay(t()) :: integer
  def next_delay(
        %__MODULE__{
          current_delay: current_delay,
          max_delay: max_delay,
          initial_delay: initial_delay
        } = _s
      ) do
    jitter = :rand.uniform() * 0.5
    jitter_ammount = jitter * initial_delay
    round(min(current_delay, max_delay) + jitter_ammount)
  end

  @spec metadata(t()) :: map()
  def metadata(%__MODULE__{watcher: watcher, resource_version: rv, k8s_watcher_ref: ref} = _s) do
    %{module: watcher, rv: rv, is_watcher_active: ref != nil}
  end

  @spec should_retry(t()) :: boolean()
  def should_retry(%__MODULE__{should_retry_watch: should_retry_watch} = _state),
    do: should_retry_watch
end
