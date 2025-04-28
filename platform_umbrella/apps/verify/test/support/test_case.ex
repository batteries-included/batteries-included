defmodule Verify.TestCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using options do
    install_spec = Keyword.get(options, :install_spec, :int_test)

    quote do
      use Wallaby.DSL

      import Verify.TestCase, only: [verify: 3, get_tmp_dir: 1]

      require Logger

      setup_all do
        Logger.debug("Starting Kind for spec: #{unquote(install_spec)}")
        tmp_dir = get_tmp_dir(__MODULE__)
        File.mkdir_p!(tmp_dir)

        {:ok, url} = Verify.KindInstallWorker.start(__MODULE__, unquote(install_spec))
        Application.put_env(:wallaby, :screenshot_dir, tmp_dir)
        Application.put_env(:wallaby, :base_url, url)

        # Make sure to clean up after ourselves
        # Stopping will also remove specs
        on_exit(&Verify.KindInstallWorker.stop_all/0)

        tested_version = CommonCore.Defaults.Images.batteries_included_version()

        Logger.info("Testing version: #{tested_version} of batteries included: #{url}")

        {:ok, [control_url: url, tested_version: tested_version, tmp_dir: tmp_dir]}
      end

      setup do
        {:ok, session} = unquote(__MODULE__).start_session()

        {:ok, [session: session]}
      end
    end
  end

  @spec get_tmp_dir(module()) :: String.t()
  def get_tmp_dir(mod) do
    Path.join([Verify.PathHelper.tmp_dir!(), "bi-int-test", Atom.to_string(mod)])
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

  # Adapted from Wallaby.Feature.feature/3
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
      name = ExUnit.Case.register_test(mod, file, line, :integration, message, [:verify])

      def unquote(name)(unquote(context)), do: unquote(contents)
    end
  end

  @spec rage_output_for_test(module(), binary()) :: String.t()
  def rage_output_for_test(mod, message) do
    tmp_dir = get_tmp_dir(mod)
    name = String.replace(message, " ", "_")

    time = :second |> :erlang.system_time() |> to_string()
    Path.join([tmp_dir, "#{time}_#{name}.json"])
  end
end
