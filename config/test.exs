import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :github_elixir_service, GithubElixirService.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "github_elixir_service_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :github_elixir_service, GithubElixirServiceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "xVrlhW5pBwPKFxWjoKpXXIWzgbeELCYuN49XH5ISp3mXSvWxs6NwMNXGbKAHSHYh",
  server: false

# In test we don't send emails
config :github_elixir_service, GithubElixirService.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Oban configs for test
config :github_elixir_service, Oban,
  repo: GithubElixirService.Repo,
  queues: [default: 10],
  plugins: false

config :github_elixir_service, :webhook_snooze_time, 60
