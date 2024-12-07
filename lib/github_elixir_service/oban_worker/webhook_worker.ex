defmodule GithubElixirService.ObanWorker.WebhookWorker do
  use Oban.Worker, queue: :default, max_attempts: 1
  require Logger

  alias GithubElixirService.GithubClient
  alias GithubElixirService.HttpClient

  @spec perform(map()) :: :ok | {:error, any()}
  def perform(%{"user" => user, "repository" => repo}) do
    webhook_url = System.get_env("WEBHOOK_URL")
    headers = [{"Content-Type", "application/json"}]

    with {:ok, payload} <- GithubClient.get_issues_and_contributors(user, repo),
         body <- Jason.encode!(payload),
         {:ok, %HTTPoison.Response{status_code: status_code}} when status_code in [200, 201] <-
           HttpClient.post(webhook_url, body, headers) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to send to webhook: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
