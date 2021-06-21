defmodule KubeUsage.Repo do
  use Ecto.Repo,
    otp_app: :kube_usage,
    adapter: Ecto.Adapters.Postgres
end
