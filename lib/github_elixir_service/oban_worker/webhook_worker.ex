defmodule GithubElixirService.ObanWorker.WebhookWorker do
  use Oban.Worker, queue: :default, max_attempts: 1
  require Logger

  alias GithubElixirService.GithubClient

  @spec perform(map()) :: :ok | {:error, any()}
  def perform(%{"user" => user, "repository" => repo}) do
    payload = GithubClient.get_issues_and_contributors(user, repo)
    webhook_url = System.get_env("WEBHOOK_URL")

    headers = [{"Content-Type", "application/json"}]
    body = Jason.encode!(payload)

    case HTTPoison.post(webhook_url, body, headers) do
      {:ok, _response} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to send to webhook: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
