defmodule Verify.TestCase do
  @moduledoc false
require Logger

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
        on_exit(fn ->
          Verify.KindInstallWorker.stop_all()
        end)

        tested_version = CommonCore.Defaults.Images.batteries_included_version()

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

          #
          # Yes 75 Seconds. Kubernetes will take a while to scale the other revision down
          # and the new one up. We can't really do anything about that. It takes 60 seconds
          # usually with a 15 second safety margin.
          #
          Logger.info("control server flap required (version=latest). Sleeping for 75 seconds")
          Process.sleep(75_000)
        else
          Logger.info("Testing version #{tested_version} of batteries included")
        end

        {:ok, [control_url: url]}
      end

      setup do
        {:ok, session} =
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

        {:ok, [session: session]}
      end
    end
  end
end
