defmodule Verify.TestCase.Util do
  @moduledoc """
  Contains utility functions and macros.
  Don't import / alias Wallaby here. Move those to `Helpers`
  """
  alias CommonCore.Batteries.Catalog
  alias Verify.BatteryInstallWorker
  alias Verify.ImagePullWorker
  alias Verify.PathHelper

  require Logger

  # Adapted from Wallaby.Feature.feature/3
  @doc """
  `verify` wraps ExUnit.test so that test failures take a screenshot and runs `bi rage`.

  The context will automatically be populated with:
  - A wallaby session set to the correct URL: `session`
  - A module specific temp directory. This directory is automatically uploaded on failure in CI: `tmp_dir`
  - The tested version: `tested_version`
  - The URL of the control server: `control_url`
  - The name/pid of the BatteryInstallWorker: `battery_install_worker`
  - The path to the kube config file for the cluster: `kube_config_path`
  - The name/pid of the ImagePullWorker: `image_pull_worker`
  - The list of requested images and batteries: `requested_{batteries,images}`
  """
  defmacro verify(message, context \\ quote(do: _), contents) do
    %{module: mod, file: file, line: line} = __CALLER__

    contents =
      quote do
        try do
          unquote(contents)
          :ok
        rescue
          e ->
            out = unquote(__MODULE__).rage_output_for_test(unquote(mod), unquote(message))

            Wallaby.Feature.Utils.take_screenshots_for_sessions(self(), unquote(message))
            # taking a screenshot writes the paths without a final newline so add it here
            IO.write("\n")
            Verify.KindInstallWorker.rage(unquote(mod), out)

            reraise(e, __STACKTRACE__)
        end
      end

    context = Macro.escape(context)
    contents = Macro.escape(contents, unquote: true)

    quote bind_quoted: [
            mod: mod,
            file: file,
            line: line,
            context: context,
            contents: contents,
            message: message
          ] do
      name = ExUnit.Case.register_test(mod, file, line, :verification, message, [:verify])

      def unquote(name)(unquote(context)), do: unquote(contents)
    end
  end

  @spec prepull_images(GenServer.name(), list(atom() | String.t())) :: :ok
  def prepull_images(_pid, []), do: :ok

  def prepull_images(pid, images) do
    Enum.each(images, &ImagePullWorker.pull_image(pid, &1))
  end

  @spec install_batteries(GenServer.name(), list(atom() | {atom() | map()})) :: :ok | list(atom())
  def install_batteries(worker_pid, batteries \\ [])

  def install_batteries(worker_pid, battery) when is_atom(battery), do: install_battery(worker_pid, {battery, %{}})

  def install_batteries(_worker_pid, []), do: :ok

  def install_batteries(worker_pid, batteries) do
    Enum.map(batteries, &install_battery(worker_pid, &1))
  end

  defp install_battery(pid, type) when is_atom(type), do: install_battery(pid, {type, %{}})

  defp install_battery(pid, {type, config}) do
    case Catalog.get(type) do
      nil ->
        raise "Couldn't find battery: #{inspect(type)}"

      battery ->
        BatteryInstallWorker.install_battery(pid, battery, config)
    end
  end

  @spec uninstall_batteries(GenServer.name(), list(atom())) :: :ok | list(term())
  def uninstall_batteries(worker_pid, battery) when is_atom(battery), do: uninstall_batteries(worker_pid, [battery])

  def uninstall_batteries(_worker_pid, []), do: :ok

  def uninstall_batteries(worker_pid, batteries) do
    Enum.map(batteries, fn type ->
      case Catalog.get(type) do
        nil ->
          raise "Couldn't find battery: #{inspect(type)}"

        battery ->
          BatteryInstallWorker.uninstall_battery(worker_pid, battery)
      end
    end)
  end

  @spec get_tmp_dir(module()) :: String.t()
  def get_tmp_dir(mod) do
    Path.join([PathHelper.tmp_dir!(), "bi-int-test", Atom.to_string(mod)])
  end

  @spec rage_output_for_test(module(), binary()) :: String.t()
  def rage_output_for_test(mod, message) do
    tmp_dir = get_tmp_dir(mod)
    name = String.replace(message, " ", "_")

    time = :second |> :erlang.system_time() |> to_string()
    Path.join([tmp_dir, "#{time}_#{name}.json"])
  end

  @spec wait_for_images(GenServer.name(), list(), non_neg_integer()) :: :ok
  def wait_for_images(pid, images, timeout \\ 60_000)

  def wait_for_images(_pid, [] = _images, _timeout), do: :ok

  def wait_for_images(pid, images, timeout) do
    start_time = DateTime.utc_now()
    end_time = DateTime.add(start_time, timeout, :millisecond)

    :ok = do_wait_on_images(images, pid, end_time, remaining(end_time))

    diff = DateTime.diff(DateTime.utc_now(), start_time, :millisecond)
    Logger.debug("Finished checking in #{diff} milliseconds")
    :ok
  end

  # there's no more images to check
  defp do_wait_on_images([] = _images, _pid, _end_time, _remaining), do: :ok

  # we're out of time
  defp do_wait_on_images(_images, _pid, _end_time, remaining) when remaining < 0, do: :ok

  # still have images to check
  defp do_wait_on_images(images, pid, end_time, _remaining) do
    waiting =
      Enum.filter(images, fn image ->
        case Verify.ImagePullWorker.image_status(pid, image) do
          # if we're still pulling, keep the image
          status when status in ~w(running retrying)a ->
            Process.sleep(500)
            true

          # else remove it
          _ ->
            false
        end
      end)

    do_wait_on_images(waiting, pid, end_time, remaining(end_time))
  end

  defp remaining(end_time) do
    DateTime.diff(end_time, DateTime.utc_now(), :millisecond)
  end

  @spec start_session() :: {:ok, Wallaby.Session.t()} | {:error, Wallaby.reason()}
  def start_session do
    Wallaby.start_session(
      max_wait_time: 60_000,
      capabilities: %{
        headless: true,
        javascriptEnabled: true,
        loadImages: true,
        chromeOptions: %{
          args: [
            # Lets act like the world is run on macbooks that
            # all of sillion valley uses
            #
            # Fix this at some point
            "window-size=1920,1080",
            # We don't want to see the browser
            "--headless",
            "--fullscreen",
            # Incognito mode means no caching for real
            # Unfortunately, chrome doesn't allow http requests at all incognito
            # "--incognito",
            # Seems to be better for stability
            "--no-sandbox",
            # Yeah this will run in CI
            "--disable-gpu",
            # Disable dev shm usage
            # This is needed for CI environments like GitHub Actions
            # where /dev/shm is super small
            #
            # See
            # https://github.com/elixir-wallaby/wallaby/issues/468#issuecomment-1113520767
            "--disable-dev-shm-usage",
            # Please google go away
            "--disable-extensions",
            "--disable-login-animations",
            "--no-default-browser-check",
            "--no-first-run",
            "--ignore-certificate-errors"
          ]
        }
      }
    )
  end
end
