defmodule Verify.TestCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using options do
    install_spec = Keyword.get(options, :install_spec, :int_test)
    batteries = Keyword.get(options, :batteries, [])
    images = Keyword.get(options, :images, [])

    quote do
      unquote(__prelude(batteries, images))
      unquote(__setup_all(batteries, images, install_spec))
      unquote(__setup())
    end
  end

  def __prelude(batteries, images) do
    quote do
      # copied from `use Wallaby.DSL`
      # we want to override visit/2
      import Kernel, except: [tap: 2]
      import Verify.TestCase.Helpers
      import Verify.TestCase.Util
      import Wallaby.Browser, except: [visit: 2]

      alias Wallaby.Browser
      alias Wallaby.Element
      alias Wallaby.Query

      # Kernel.tap/2 was introduced in 1.12 and conflicts with Browser.tap/2
      require Logger

      ExUnit.Case.register_module_attribute(__MODULE__, :batteries, accumulate: true)
      ExUnit.Case.register_module_attribute(__MODULE__, :images, accumulate: true)

      Enum.each(unquote(batteries), &Module.put_attribute(__MODULE__, :batteries, &1))
      Enum.each(unquote(images), &Module.put_attribute(__MODULE__, :images, &1))

      @moduletag :cluster_test

      @args ["--class=bi-int-test"]
    end
  end

  def __setup_all(batteries, images, install_spec) do
    quote do
      setup_all do
        batteries = unquote(batteries)
        images = unquote(images)

        image_pid =
          start_supervised!({
            Verify.ImagePullWorker,
            [
              name: {:via, Registry, {Verify.Registry, __MODULE__.ImagePullWorker, Verify.ImagePullWorker}}
            ]
          })

        # kick off image pull as early as possible
        prepull_images(image_pid, images)

        Logger.debug("Starting Kind for spec: #{unquote(install_spec)}")
        tmp_dir = get_tmp_dir(__MODULE__)

        {:ok, url, kube_config_path} =
          Verify.KindInstallWorker.start(__MODULE__, unquote(install_spec))

        # Make sure to clean up after ourselves
        # Stopping will also remove specs
        on_exit(&Verify.KindInstallWorker.stop_all/0)

        :ok = wait_for_images(image_pid, images)

        Application.put_env(:wallaby, :screenshot_dir, tmp_dir)
        Application.put_env(:wallaby, :base_url, url)

        # install any requested batteries
        {:ok, session} = start_session()

        install_pid =
          start_supervised!({
            Verify.BatteryInstallWorker,
            [
              name: {:via, Registry, {Verify.Registry, __MODULE__.BatteryInstallWorker, Verify.BatteryInstallWorker}},
              session: session
            ]
          })

        install_batteries(install_pid, batteries)
        on_exit(fn -> Wallaby.end_session(session) end)

        tested_version = CommonCore.Defaults.Images.batteries_included_version()
        Logger.info("Testing version: #{tested_version} of batteries included: #{url}")

        {:ok,
         [
           requested_batteries: batteries,
           requested_images: images,
           image_pull_worker: image_pid,
           battery_install_worker: install_pid,
           control_url: url,
           kube_config_path: kube_config_path,
           tested_version: tested_version,
           tmp_dir: tmp_dir
         ]}
      end
    end
  end

  def __setup do
    quote do
      setup do
        {:ok, session} = start_session()

        on_exit(fn -> Wallaby.end_session(session) end)
        {:ok, [session: session]}
      end
    end
  end
end
