defmodule GithubElixirService.ObanWorker.WebhookWorker do
  @moduledoc """
  This worker schedules a job to fetch GitHub repository data (issues and contributors)
  and sends the processed data to a specified webhook after 24 hours.

  It uses the `GithubElixirService.GithubClient` to collect the data.
  """

  use Oban.Worker, queue: :default, max_attempts: 1
  require Logger

  alias GithubElixirService.GithubClient
  alias GithubElixirService.HttpClient

  @spec schedule(String.t(), String.t()) :: {:ok, Oban.Job.t()} | {:error, any()}
  def schedule(user, repo) do
    snooze_time = Application.get_env(:github_elixir_service, :webhook_snooze_time)

    with {:ok, payload} <- GithubClient.get_issues_and_contributors(user, repo),
         body <- Jason.encode!(payload),
         {:ok, scheduled_job = %Oban.Job{}} <-
           Oban.insert(new(%{"body" => body}, schedule_in: snooze_time)) do
      {:ok, scheduled_job}
    else
      {:error, reason} ->
        Logger.error("Failed to schedule job: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @spec perform(Oban.Job.t()) :: :ok | {:error, any()}
  def perform(%Oban.Job{args: %{"body" => body}}) do
    webhook_url = Application.get_env(:github_elixir_service, :webhook_url)
    headers = [{"Content-Type", "application/json"}]

    case HttpClient.post(webhook_url, body, headers) do
      {:ok, %{status_code: status_code}} when status_code in [200, 201] ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to send to webhook: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
