defmodule GithubElixirService.Repo do
  use Ecto.Repo,
    otp_app: :github_elixir_service,
    adapter: Ecto.Adapters.Postgres
end
