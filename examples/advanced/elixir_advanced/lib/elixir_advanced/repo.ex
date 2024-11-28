defmodule ElixirAdvanced.Repo do
  use Ecto.Repo,
    otp_app: :elixir_advanced,
    adapter: Ecto.Adapters.Postgres
end
