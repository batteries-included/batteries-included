ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(ControlServer.Repo, :auto)
Application.ensure_all_started(:mox)
Mox.defmock(KubeServices.Keycloak.TeslaMock, for: Tesla.Adapter)
