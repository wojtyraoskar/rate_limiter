defmodule RL.Repo do
  use Ecto.Repo,
    otp_app: :rate_limiter,
    adapter: Ecto.Adapters.Postgres
end
