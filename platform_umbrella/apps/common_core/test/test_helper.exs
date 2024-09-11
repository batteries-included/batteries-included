{:ok, _} = Application.ensure_all_started(:mox)
{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
