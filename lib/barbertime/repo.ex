defmodule Barbertime.Repo do
  use Ecto.Repo,
    otp_app: :barbertime,
    adapter: Ecto.Adapters.Postgres
end
