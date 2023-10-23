{:ok, _} = Application.ensure_all_started(:ex_machina)
K8s.Client.DynamicHTTPProvider.start_link(nil)

ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(ControlServer.Repo, :manual)
