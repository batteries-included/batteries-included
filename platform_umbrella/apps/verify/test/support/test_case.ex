defmodule Verify.TestCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using options do
    install_spec_path = Keyword.get(options, :install_spec, "bootstrap/local.spec.json")

    quote do
      def install_spec_path, do: unquote(install_spec_path)

      setup do
        Verify.KindInstallWorker.start(install_spec_path())

        on_exit(fn ->
          Verify.KindInstallWorker.stop_all()
        end)
      end
    end
  end
end
