{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(HomeBase.Repo, :manual)
