{:ok, _} = Application.ensure_all_started(:mox)

Mox.defmock(EventCenter.MockDatabase, for: EventCenter.Database.Behaviour)
Mox.defmock(EventCenter.MockKeycloak, for: EventCenter.Keycloak.Behaviour)
Mox.defmock(EventCenter.MockKeycloakSnapshot, for: EventCenter.KeycloakSnapshot.Behaviour)
Mox.defmock(EventCenter.MockKubeSnapshot, for: EventCenter.KubeSnapshot.Behaviour)
Mox.defmock(EventCenter.MockKubeState, for: EventCenter.KubeState.Behaviour)
Mox.defmock(EventCenter.MockSystemStateSummary, for: EventCenter.SystemStateSummary.Behaviour)
