{:ok, _} = Application.ensure_all_started([:ex_machina, :mox])
ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(ControlServer.Repo, :auto)
