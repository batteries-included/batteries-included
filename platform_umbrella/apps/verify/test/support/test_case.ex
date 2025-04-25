defmodule Verify.TestCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using options do
    install_spec = Keyword.get(options, :install_spec, :int_test)

    quote do
      use Wallaby.DSL

      require Logger

      setup_all do
        Logger.debug("Starting Kind for spec: #{unquote(install_spec)}")
        {:ok, url} = Verify.KindInstallWorker.start(unquote(install_spec))
        Application.put_env(:wallaby, :base_url, url)

        # Make sure to clean up after ourselves
        # Stopping will also remove specs
        on_exit(&Verify.KindInstallWorker.stop_all/0)

        tested_version = CommonCore.Defaults.Images.batteries_included_version()

        Logger.info("Testing version: #{tested_version} of batteries included: #{url}")

        {:ok, [control_url: url, tested_version: tested_version]}
      end

      setup do
        {:ok, session} = unquote(__MODULE__).start_session()

        {:ok, [session: session]}
      end
    end
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
            "window-size=1280,720",
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
