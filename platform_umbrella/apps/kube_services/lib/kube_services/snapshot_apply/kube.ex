defmodule KubeServices.SnapshotApply.KubeApply do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.Resources.Hashing
  alias CommonCore.Resources.RootResourceGenerator
  alias CommonCore.StateSummary
  alias ControlServer.SnapshotApply.KubeEctoSteps
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias ControlServer.SnapshotApply.ResourcePath
  alias ControlServer.SnapshotApply.UmbrellaSnapshot
  alias KubeServices.KubeState
  alias KubeServices.SnapshotApply.ApplyResource

  require Logger

  @me __MODULE__
  @state_opts [
    :apply_kube_func,
    :kube_connection,
    :stream_concurrency
  ]

  defmodule State do
    @moduledoc false
    typedstruct do
      field :kube_connection, K8s.Conn.t() | nil
      field :apply_kube_func, any()
      field :stream_concurrency, non_neg_integer(), default: 5
    end

    def new(opts) do
      %__MODULE__{
        apply_kube_func: Keyword.get(opts, :apply_kube_func, &ApplyResource.apply/2),
        kube_connection: Keyword.get_lazy(opts, :kube_connection, &CommonCore.ConnectionPool.get!/0),
        stream_concurrency: Keyword.get(opts, :stream_concurrency, 5)
      }
    end
  end

  @spec start_link(keyword) :: GenServer.on_start()
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

  def prepare(%UmbrellaSnapshot{} = us) do
    KubeEctoSteps.create_snap(%{umbrella_snapshot_id: us.id})
  end

  @spec generate(KubeSnapshot.t(), StateSummary.t()) :: any
  def generate(snap, summary) do
    GenServer.call(@me, {:generate, snap, summary}, 600_000)
  end

  @spec apply(KubeSnapshot.t(), list(ResourcePath.t())) :: any
  def apply(snap, resource_paths) do
    GenServer.call(@me, {:apply, snap, resource_paths}, 600_000)
  end

  @impl GenServer
  def handle_call({:generate, snap, summary}, _from, state) do
    {:reply, do_generate(snap, summary, state), state}
  end

  @impl GenServer
  def handle_call({:apply, snap, resource_paths}, _from, state) do
    {:reply, do_apply(snap, resource_paths, state), state}
  end

  defp do_generate(%KubeSnapshot{} = snap, %StateSummary{} = summary, _state) do
    with {:ok, up_g_snap} <- KubeEctoSteps.update_snap_status(snap, :generation),
         resource_map = RootResourceGenerator.materialize(summary),
         {:ok, %{resource_paths: {_cnt, resource_paths}}} <-
           KubeEctoSteps.snap_generation(up_g_snap, resource_map) do
      {:ok, {resource_paths, resource_map}}
    end
  end

  defp do_apply(%KubeSnapshot{} = snap, {resource_paths, resource_map}, %State{} = state) do
    # this is the beating heart of snapshot apply
    # It's a beast
    # First we set that this kube snapshot is in the applying phase
    # Push resource paths that need it to kubernetes, updating the resource paths in the db
    # Then update the kube snapshot one final time
    #
    # This whole thing tries really really really hard to never throw
    # instead errors are propogated everywhere so that they can be written as status
    # results and error messages.
    with {:ok, up_g_snap} <- KubeEctoSteps.update_snap_status(snap, :applying),
         {:ok, apply_result} <- apply_resource_paths(resource_paths, resource_map, state) do
      final_snap_update(up_g_snap, apply_result)
    end
  end

  defp apply_resource_paths(paths, resource_map, state) do
    {needs_apply, matches} =
      Enum.split_with(paths, fn %ResourcePath{} = rp ->
        kube_state_different?(rp, state)
      end)

    Logger.debug("Need Apply: #{length(needs_apply)} Matches: #{length(matches)}")

    with {_update_cnt, fail_update_match_cnt} <-
           update_matching_resource_paths(matches, state),
         {:ok, applied_rp} <- apply_needs_apply_resource_paths(needs_apply, resource_map, state) do
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
    KubeEctoSteps.update_snap_status(snap, :ok)
  end

  defp final_snap_update(snap, %{fail_kube_apply_count: _}) do
    KubeEctoSteps.update_snap_status(snap, :error)
  end

  defp update_matching_resource_paths(paths, _server_state) do
    KubeEctoSteps.update_all_rp(paths, true, "Hash Match")
  end

  defp apply_needs_apply_resource_paths(paths, resource_map, %{stream_concurrency: stream_concurrency} = server_state) do
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
            exp ->
              {:error, %{exception: exp}}

              # Write the result back to the database
          end

        is_success = resource_path_result_is_success?(result)
        reason_string = reason_string(reason)
        KubeEctoSteps.update_rp(rp, is_success, reason_string)
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

  defp kube_state_different?(%ResourcePath{} = rp, _server_state) do
    case KubeState.get(rp.type, rp.namespace, rp.name) do
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
  defp reason_string(%K8s.Client.APIError{message: message}) when is_binary(message), do: message
  defp reason_string(obj), do: inspect(obj)
end
