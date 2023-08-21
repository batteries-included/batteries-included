Application.ensure_all_started(:mox)
Mox.defmock(CommonCore.Keycloak.TeslaMock, for: Tesla.Adapter)
ExUnit.start()
