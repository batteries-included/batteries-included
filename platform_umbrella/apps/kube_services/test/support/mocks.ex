alias KubeServices.RoboSRE.Executor
alias KubeServices.RoboSRE.Handler

{:ok, _} = Application.ensure_all_started(:mox)

Mox.defmock(KubeServices.RoboSRE.MockDeleteResourceExecutor, for: Executor)
Mox.defmock(KubeServices.RoboSRE.MockRestartKubeStateExecutor, for: Executor)
Mox.defmock(KubeServices.RoboSRE.MockStaleResourceHandler, for: Handler)
Mox.defmock(KubeServices.RoboSRE.MockStuckKubeStateHandler, for: Handler)
Mox.defmock(KubeServices.MockKubeState, for: KubeServices.KubeState.Behaviour)
Mox.defmock(KubeServices.MockResourceDeleter, for: KubeServices.ResourceDeleter.Behaviour)
Mox.defmock(KubeServices.MockStale, for: KubeServices.Stale.Behaviour)
Mox.defmock(KubeServices.KubeState.MockCanary, for: KubeServices.KubeState.Canary.Behaviour)
