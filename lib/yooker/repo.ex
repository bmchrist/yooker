defmodule Yooker.Repo do
  use Ecto.Repo,
    otp_app: :yooker,
    adapter: Ecto.Adapters.Postgres
end
