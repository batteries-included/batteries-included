{:ok, _} = Application.ensure_all_started(:mox)

Mox.defmock(CommonCore.Keycloak.TeslaMock, for: Tesla.Adapter)
Mox.defmock(CommonCore.JWK.LoaderMock, for: CommonCore.JWK.Loader)
Mox.defmock(CommonCore.Accounts.EnvFetcherMock, for: CommonCore.Accounts.EnvFetcher)
