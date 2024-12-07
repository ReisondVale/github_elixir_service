ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(GithubElixirService.Repo, :manual)
Mox.defmock(GithubElixirService.MockHttpClient, for: GithubElixirService.HttpClient)
Application.put_env(:github_elixir_service, :http_client, GithubElixirService.MockHttpClient)
