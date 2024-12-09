defmodule GithubElixirServiceWeb.WebhookController do
  @moduledoc """
  This controller handles requests related to GitHub webhook integration.
  """

  use GithubElixirServiceWeb, :controller

  require Logger
  alias GithubElixirService.ObanWorker.WebhookWorker

  @spec fetch_data_issues(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def fetch_data_issues(conn, %{"user" => user, "repository" => repo}) do
    case WebhookWorker.schedule(user, repo) do
      {:ok, job} ->
        Logger.info("GitHub data has been scheduled to be sent to the webhook in 24 hours",
          job: job
        )

        conn
        |> put_status(200)
        |> json(%{message: "Webhook will be sent in 24 hours"})

      {:error, reason} ->
        Logger.error("Error to fetch data issues", reason: reason)

        conn
        |> put_status(500)
        |> json(%{message: "Error scheduling webhook"})
    end
  end
end
