{:ok, _} = Application.ensure_all_started(:mox)
Mox.defmock(HomeBase.Accounts.AdminTeams.EnvFetcherMock, for: HomeBase.Accounts.AdminTeams.EnvFetcher)
