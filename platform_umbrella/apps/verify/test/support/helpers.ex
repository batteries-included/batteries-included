defmodule Verify.TestCase.Helpers do
  @moduledoc false

  alias Verify.PathHelper
  alias Wallaby.Query

  # Adapted from Wallaby.Feature.feature/3
  @doc """
  `verify` wraps ExUnit.test so that test failures take a screenshot and runs `bi rage`.

  The context will automatically be populated with:
  - A wallaby session set to the correct URL: `session`
  - A module specific temp directory. This directory is automatically uploaded on failure in CI: `tmp_dir`
  - The tested version: `tested_version`
  - The URL of the control server: `control_url`
  - The name/pid of the BatteryInstallWorker: `battery_install_worker`
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
      name = ExUnit.Case.register_test(mod, file, line, :integration, message, [:verify])

      def unquote(name)(unquote(context)), do: unquote(contents)
    end
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

  def table_row(opts \\ []), do: Query.css("table tbody tr", opts)
  def h3(text, opts \\ []), do: Query.css("h3", Keyword.put(opts, :text, text))
end
