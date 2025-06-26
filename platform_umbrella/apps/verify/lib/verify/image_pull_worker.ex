defmodule Verify.ImagePullWorker do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.Defaults.Image
  alias CommonCore.Defaults.Images

  require Logger

  typedstruct module: State do
    field :tasks, :map, default: []
    field :slug, :string
  end

  @state_opts ~w(tasks slug)a

  def start_link(opts \\ []) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  @impl GenServer
  def init(args) do
    Logger.info("Starting ImagePullWorker")
    {:ok, struct!(State, args)}
  end

  @impl GenServer
  def handle_call({:status, image}, _from, state) do
    Logger.debug("Looking up status of image: #{image}")

    status =
      case state.tasks[key(image)] do
        {^image, %Task{}} ->
          :running

        {^image, {_, 0}} ->
          :complete

        {^image, :retrying} ->
          :retrying

        _ ->
          :unknown
      end

    {:reply, status, state}
  end

  @impl GenServer
  def handle_cast({:pull, image}, state), do: pull(image, state)

  @impl GenServer
  def handle_info({:pull, image}, state), do: pull(image, state)

  @impl GenServer
  def handle_info({ref, result}, state) do
    # The task finished so we can demonitor its reference
    Process.demonitor(ref, [:flush])

    {key, {image, _task}} = get_task_for_ref(state, ref)
    Logger.debug("Got #{inspect(result)} for image #{image}")

    update =
      case result do
        {_stdout, 0} ->
          {image, result}

        _ ->
          Process.send_after(self(), {:pull, image}, 5_000)
          {image, :retrying}
      end

    state = put_in(state.tasks[key], update)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, _, _, reason}, state) do
    {key, {image, _task}} = get_task_for_ref(state, ref)
    Logger.error("Image key: #{key} failed to pull with reason: #{inspect(reason)}")

    # retry after delay
    Process.send_after(self(), {:pull, image}, 5_000)
    {:noreply, state}
  end

  @spec pull_image(GenServer.name(), atom | String.t()) :: term()
  def pull_image(name, image) do
    GenServer.cast(name, {:pull, image})
  end

  @spec image_status(GenServer.name(), atom | String.t()) :: term()
  def image_status(name, image) do
    GenServer.call(name, {:status, image})
  end

  defp build_docker_pull_cmd(key, slug) when is_atom(key), do: key |> resolve_image() |> build_docker_pull_cmd(slug)

  defp build_docker_pull_cmd(image, slug) do
    fn ->
      Logger.info("Trying to pre-pull image: #{image}")
      System.cmd("docker", ["exec", "#{slug}-control-plane", "crictl", "pull", image], stderr_to_stdout: true)
    end
  end

  defp resolve_image(key), do: key |> Images.get_image!() |> Image.default_image()

  defp get_task_for_ref(state, find_ref) do
    Enum.find(state.tasks, fn
      {_, {_, %Task{ref: ^find_ref}}} -> true
      _ -> false
    end)
  end

  defp key(image) when is_atom(image), do: image

  defp key(image) when is_binary(image),
    do: image |> String.replace("/", "_") |> String.replace(":", "_") |> String.replace("-", "_") |> String.to_atom()

  defp pull(image, %{slug: slug} = state) do
    task_fn = build_docker_pull_cmd(image, slug)
    task = Task.Supervisor.async_nolink(Verify.TaskSupervisor, task_fn)

    state = put_in(state.tasks[key(image)], {image, task})

    {:noreply, state}
  end
end
