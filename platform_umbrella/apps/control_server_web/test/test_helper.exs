K8s.Client.DynamicHTTPProvider.start_link(nil)

Ecto.Adapters.SQL.Sandbox.mode(ControlServer.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(KubeUsage.Repo, :manual)

{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
