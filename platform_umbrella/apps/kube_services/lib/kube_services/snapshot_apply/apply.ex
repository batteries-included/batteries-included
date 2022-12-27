defmodule KubeServices.SnapshotApply.Apply do
  use GenServer

  import ControlServer.SnapshotApply.EctoSteps

  alias ControlServer.SnapshotApply.EctoSteps
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias ControlServer.SnapshotApply.ResourcePath
  alias ControlServer.SystemState.Summarizer

  alias KubeResources.ConfigGenerator

  alias KubeExt.ApplyResource
  alias KubeExt.KubeState
  alias KubeExt.Hashing

  require Logger

  @me __MODULE__
  @state_opts [
    :resource_gen_func,
    :system_state_summarizer_func,
    :apply_kube_func,
    :kube_state_get_func,
    :kube_connection,
    :stream_concurrency
  ]

  defmodule State do
    defstruct resource_gen_func: nil,
              system_state_summarizer_func: nil,
              kube_connection: nil,
              apply_kube_func: nil,
              kube_state_get_func: nil,
              stream_concurrency: 5

    def new(opts) do
      %__MODULE__{
        resource_gen_func: Keyword.get(opts, :resource_gen_func, &ConfigGenerator.materialize/1),
        system_state_summarizer_func:
          Keyword.get(opts, :system_state_summarizer_func, &Summarizer.new/0),
        apply_kube_func: Keyword.get(opts, :apply_kube_func, &ApplyResource.apply/2),
        kube_state_get_func: Keyword.get(opts, :kube_state_get_func, &KubeState.get/3),
        kube_connection: Keyword.get_lazy(opts, :kube_connection, &KubeExt.ConnectionPool.get/0),
        stream_concurrency: Keyword.get(opts, :stream_concurrency, 5)
      }
    end
  end

  @spec start_link(keyword) :: {:ok, pid}
  def start_link(opts) do
    {state_opts, opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@state_opts)

    {:ok, pid} = result = GenServer.start_link(@me, state_opts, opts)
    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.", pid: pid)
    result
  end

  @impl GenServer
  def init(opts) do
    {:ok, State.new(opts)}
  end

  @spec run :: {:ok, KubeSnapshot.t()} | {:error, any()}
  def run do
    case EctoSteps.create_snap() do
      {:ok, snap} -> run(snap)
      {:error, err} -> {:error, err}
      err -> {:error, %{error: err}}
    end
  end

  @spec run(KubeSnapshot.t()) :: any
  def run(snap) do
    GenServer.call(@me, {:run, snap}, 600_000)
  end

  @spec cast_run :: :ok | {:error, any}
  def cast_run do
    case EctoSteps.create_snap() do
      {:ok, snap} -> cast_run(snap)
      {:error, err} -> {:error, err}
      err -> {:error, %{error: err}}
    end
  end

  def cast_run(snap) do
    GenServer.cast(@me, {:run, snap})
  end

  @impl GenServer
  def handle_cast({:run, snap}, state) do
    with {:ok, _snap} <- do_run(snap, state) do
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_call({:run, snap}, _from, state) do
    {:reply, do_run(snap, state), state}
  end

  defp do_run(
         %KubeSnapshot{} = snap,
         %State{} = server_state
       ) do
    # this is the beating heart of snapshot apply
    # It's a beast
    # First we set that this kube snapshot is in the generation phase
    # Then we get the current state. Usually by calling `ControlServer.SystemState.Summarizer`
    # After we have the state we generate the giant map of what resources should look like
    # Then apply that to the KubeSnapshot getting a bunch of resource paths.
    # Push resource paths that need it to kubernetes, updating the resouce paths in the db
    # Then update the kube snapshot one final time
    #
    # This whole thing tries really really really hard to never throw
    # insteam errors are propogated everywhere so that they can be written as status
    # results and error messages.
    with {:ok, up_g_snap} <- update_snap_status(snap, :generation),
         system_state <- do_system_state_summary(server_state),
         resource_map <- do_resource_gen(system_state, server_state),
         {:ok, %{resource_paths: {_cnt, resource_paths}}} <-
           snap_generation(up_g_snap, resource_map),
         {:ok, up_g_snap} <- update_snap_status(snap, :applying),
         {:ok, apply_result} <- apply_resource_paths(resource_paths, resource_map, server_state) do
      final_snap_update(up_g_snap, apply_result)
    else
      {:error, err} -> {:error, err}
      err -> {:error, %{error: err}}
    end
  end

  defp do_system_state_summary(
         %State{system_state_summarizer_func: sys_state_func} = _server_state
       ) do
    res = sys_state_func.()
    Logger.debug("System state summary created")
    res
  end

  defp do_resource_gen(system_state, %{resource_gen_func: gen_func} = _server_state) do
    res = gen_func.(system_state)
    Logger.debug("Generated new resource map from system state", map_size: map_size(res))
    res
  end

  defp apply_resource_paths(paths, resource_map, server_state) do
    {needs_apply, matches} =
      Enum.split_with(paths, fn %ResourcePath{} = rp ->
        kube_state_different?(rp, server_state)
      end)

    Logger.debug("Need Apply: #{length(needs_apply)} Matches: #{length(matches)}")

    with {_update_cnt, fail_update_match_cnt} <-
           update_matching_resource_paths(matches, server_state),
         {:ok, applied_rp} <-
           apply_needs_apply_resource_paths(needs_apply, resource_map, server_state) do
      need_match_cnt = length(matches)
      need_kube_apply_cnt = length(needs_apply)
      fail_apply_cnt = Enum.count(applied_rp, &(!&1.is_success))

      Logger.debug("Fail apply count, #{fail_apply_cnt}", fail_cnt: fail_apply_cnt)

      {:ok,
       %{
         need_match_count: need_match_cnt,
         need_kube_apply_count: need_kube_apply_cnt,
         fail_update_match_count: fail_update_match_cnt || 0,
         fail_kube_apply_count: fail_apply_cnt
       }}
    else
      {:error, err} -> {:error, err}
      err -> {:error, %{error: err}}
    end
  end

  defp final_snap_update(snap, %{fail_kube_apply_count: 0}) do
    EctoSteps.update_snap_status(snap, :ok)
  end

  defp final_snap_update(snap, %{fail_kube_apply_count: _}) do
    EctoSteps.update_snap_status(snap, :error)
  end

  defp update_matching_resource_paths(paths, _server_state) do
    EctoSteps.update_all_rp(paths, true, "Hash Match")
  end

  defp apply_needs_apply_resource_paths(
         paths,
         resource_map,
         %{stream_concurrency: stream_concurrency} = server_state
       ) do
    paths
    |> Task.async_stream(
      fn rp ->
        # Send this off to kubernetes
        # Being really sure that everything should not throw.
        {result, reason} =
          try do
            resource_map
            |> Map.get(rp.path)
            |> apply_resource_to_kube(server_state)
          rescue
            exp -> {:error, %{exception: exp}}
          end

        # Write the result back to the database
        is_success = resource_path_result_is_success?(result)
        reason_string = reason_string(reason)
        EctoSteps.update_rp(rp, is_success, reason_string)
      end,
      timeout: 10_000,
      max_concurrency: stream_concurrency,
      ordered: false
    )
    |> Enum.reduce({:ok, []}, fn
      # Handle just incase tasks got killed
      {:exit, reason}, _running_result ->
        {:error, %{task_exit: reason}}

      # Unwrap the extra ok that Tasks.async_stream add
      {:ok, update_result}, running_result ->
        # Evenything should write to db succesfully
        # but make sure of that by
        case {update_result, running_result} do
          {{:ok, rp}, {:ok, acc}} ->
            {:ok, [rp | acc]}

          {{:error, reason}, _} ->
            {:error, reason}

          {_, {:error, reason}} ->
            {:error, reason}

          {_, _} ->
            {:error, %{error: :unknown}}
        end
    end)
  end

  defp kube_state_different?(
         %ResourcePath{} = rp,
         %{kube_state_get_func: kube_state_get_func} = _server_state
       ) do
    case kube_state_get_func.(rp.type, rp.namespace, rp.name) do
      # Resource path doesn't have the whole annotated
      # resource so just check the equality of the hashes here.
      {:ok, current_resource} ->
        current_resource
        |> Hashing.get_hash()
        |> Hashing.different?(rp.hash)

      _ ->
        true
    end
  end

  defp apply_resource_to_kube(
         resource_content,
         %{apply_kube_func: apply_kube_func, kube_connection: kube_connection} = _server_state
       ) do
    case apply_kube_func.(kube_connection, resource_content) do
      %{last_result: {:ok, _result}} ->
        {:ok, :applied}

      %{last_result: {:error, %{error: error_reason}}} ->
        {:error, error_reason}

      %{last_result: {:error, reason}} ->
        {:error, reason}
    end
  end

  defp resource_path_result_is_success?(:ok), do: true
  defp resource_path_result_is_success?(_result), do: false

  defp reason_string(:applied), do: "Applied"
  defp reason_string(reason_atom) when is_atom(reason_atom), do: Atom.to_string(reason_atom)
  defp reason_string(reason) when is_binary(reason), do: reason
  defp reason_string(obj), do: inspect(obj)
end
