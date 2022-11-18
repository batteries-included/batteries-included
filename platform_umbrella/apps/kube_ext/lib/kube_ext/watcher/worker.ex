defmodule KubeExt.Watcher.Worker do
  @moduledoc """
  Continuously watch a list `Operation` for `add`, `modify`, and `delete` events.
  """

  use GenServer

  alias KubeExt.Watcher.Event
  alias KubeExt.Watcher.Core
  alias KubeExt.Watcher.State

  @state_opts [
    :client,
    :connection,
    :connection_func,
    :extra,
    :watcher,
    :resource_version,
    :should_retry_watch,
    :watch_timeout,
    :initial_delay,
    :max_delay
  ]

  def start_link, do: start_link([])

  def start_link(opts) do
    {state_opts, opts} = Keyword.split(opts, @state_opts)

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  def state(pid) do
    GenServer.call(pid, :state)
  end

  @impl GenServer
  def init(state_opts) do
    state = State.new(state_opts)
    Event.watcher_initialized(%{}, State.metadata(state))
    Process.send_after(self(), :watch, state.initial_delay)
    {:ok, %State{state | current_delay: state.initial_delay}}
  end

  @impl GenServer
  def handle_call(:state, _from, %State{} = state) do
    {:reply, state, state}
  end

  defp do_watch(state) do
    case {State.should_retry(state), Core.watch(self(), state)} do
      {_, {:ok, ref}} ->
        Event.watcher_watch_started(%{}, State.metadata(state))
        %State{state | k8s_watcher_ref: ref}

      {true, _} ->
        delay = State.next_delay(state)
        Event.watcher_watch_failed(%{}, State.metadata(state))
        Process.send_after(self(), :watch, delay)
        %State{state | k8s_watcher_ref: nil, current_delay: delay}
    end
  end

  @impl GenServer
  def handle_info(:watch, %State{resource_version: nil} = state) do
    rv = Core.get_resource_version(state)
    state = %{state | resource_version: rv}

    if rv != nil do
      Core.get_before(state)
    end

    {:noreply, do_watch(state)}
  end

  @impl GenServer
  def handle_info(:watch, %State{resource_version: _curr_rv} = state) do
    {:noreply, do_watch(state)}
  end

  @impl GenServer
  def handle_info(%HTTPoison.AsyncHeaders{}, state), do: {:noreply, state}

  @impl GenServer
  def handle_info(%HTTPoison.AsyncStatus{code: 200}, state) do
    Event.watcher_watch_succeeded(%{}, State.metadata(state))
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(%HTTPoison.AsyncStatus{code: code}, state) do
    metadata = state |> State.metadata() |> Map.put(:code, code)
    Event.watcher_watch_failed(%{}, metadata)
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, %State{} = state) do
    metadata = State.metadata(state)
    Event.watcher_chunk_received(%{}, metadata)

    {lines, buffer} =
      state.buffer
      |> KubeExt.Watcher.ResponseBuffer.add_chunk(chunk)
      |> KubeExt.Watcher.ResponseBuffer.get_lines()

    case Core.process_lines(lines, state) do
      {:ok, new_rv} ->
        Event.watcher_chunk_finished(%{}, metadata)
        {:noreply, %State{state | buffer: buffer, resource_version: new_rv}}

      {:error, :gone} ->
        Event.watcher_chunk_finished(%{}, metadata)
        {:stop, :normal, state}

      _ ->
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(%HTTPoison.AsyncEnd{}, %State{} = state) do
    Event.watcher_watch_finished(%{}, State.metadata(state))
    send(self(), :watch)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(%HTTPoison.Error{reason: {:closed, :timeout}}, %State{} = state) do
    Event.watcher_watch_timedout(%{}, State.metadata(state))
    send(self(), :watch)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, _reason}, %State{k8s_watcher_ref: k8s_ref} = state) do
    case ref == k8s_ref do
      true ->
        # If the watcher is down then restart it.
        Event.watcher_watch_down(%{}, State.metadata(state))
        state = %State{state | k8s_watcher_ref: nil}

        send(self(), :watch)
        {:noreply, state}

      _ ->
        # Otherwise we assume that it was an async task dispatched to the
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(_other, %State{} = state) do
    {:noreply, state}
  end
end
