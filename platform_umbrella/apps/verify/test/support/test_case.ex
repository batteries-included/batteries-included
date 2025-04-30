defmodule Verify.TestCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias CommonCore.Batteries.Catalog
  alias Verify.BatteryInstallWorker

  require Logger

  using options do
    install_spec = Keyword.get(options, :install_spec, :int_test)
    batteries = Keyword.get(options, :batteries, [])

    quote do
      use Wallaby.DSL

      import Verify.TestCase.Helpers

      require Logger

      ExUnit.Case.register_module_attribute(__MODULE__, :batteries)

      @moduletag :cluster_test

      setup_all do
        Logger.debug("Starting Kind for spec: #{unquote(install_spec)}")
        tmp_dir = get_tmp_dir(__MODULE__)
        File.mkdir_p!(tmp_dir)

        {:ok, url, kube_config_path} = Verify.KindInstallWorker.start(__MODULE__, unquote(install_spec))
        Application.put_env(:wallaby, :screenshot_dir, tmp_dir)
        Application.put_env(:wallaby, :base_url, url)

        # Make sure to clean up after ourselves
        # Stopping will also remove specs
        on_exit(&Verify.KindInstallWorker.stop_all/0)

        # install any requested batteries
        {:ok, session} = unquote(__MODULE__).start_session()

        worker_pid =
          start_supervised!({
            Verify.BatteryInstallWorker,
            [
              name: {:via, Registry, {Verify.Registry, __MODULE__, Verify.BatteryInstallWorker}},
              session: session
            ]
          })

        unquote(__MODULE__).install_batteries(worker_pid, unquote(batteries))

        tested_version = CommonCore.Defaults.Images.batteries_included_version()
        Logger.info("Testing version: #{tested_version} of batteries included: #{url}")

        {:ok,
         [
           battery_install_worker: worker_pid,
           control_url: url,
           kube_config_path: kube_config_path,
           tested_version: tested_version,
           tmp_dir: tmp_dir
         ]}
      end

      setup context do
        {:ok, session} = unquote(__MODULE__).start_session()

        {:ok, [session: session]}
      end
    end
  end

  def install_batteries(worker_pid, batteries \\ [])

  def install_batteries(_worker_pid, []), do: :ok

  def install_batteries(worker_pid, batteries) do
    Enum.map(batteries, fn type ->
      case Catalog.get(type) do
        nil ->
          raise "Couldn't find battery: #{inspect(type)}"

        battery ->
          BatteryInstallWorker.install_battery(worker_pid, battery)
      end
    end)
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
