defmodule Verify.TestCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  require Logger

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
        on_exit(fn ->
          Verify.KindInstallWorker.stop_all()
        end)

        tested_version = CommonCore.Defaults.Images.batteries_included_version()
        # conn = CommonCore.ConnectionPool.get!()
        # K8s.Client.wait_until(conn, operation, wait_opts)

        Logger.info("Testing version: #{tested_version} of batteries included")

        unquote(__MODULE__).check_connection(url)

        if tested_version == "latest" do
          # Ask me how fucking long it took to figure this out
          #
          # When we are testing the latest tag it's a moving target
          # So the control server will deploy a
          # snapshot with its own version as the image tag
          # during that time its possible to get a websocket
          # that leaves the browser unable to make progress.
          #
          # In the future we should:
          # - Account for that in kube bootstrap
          # - have a kubernetes client here and use that for flap detection
          # - figure out why reconnect sometimes doesn't happen on kind clusters. Though I think it's like timing and resource constraints.

          Logger.info("control server flap required (version=latest). Sleeping for 75 seconds")
          Process.sleep(75_000)
          unquote(__MODULE__).check_connection(url)
        end

        {:ok, [control_url: url]}
      end

      setup do
        {:ok, session} = unquote(__MODULE__).start_session()

        {:ok, [session: session]}
      end
    end
  end

  def check_connection(url) do
    {:ok, session} = start_session()

    session
    |> Wallaby.Browser.visit(url)
    |> Wallaby.Browser.take_screenshot()
    |> Wallaby.Browser.find(Wallaby.Query.text("Home", minimum: 1), fn _ -> Logger.info("Connected to cluster") end)

    Wallaby.end_session(session)
  end

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
