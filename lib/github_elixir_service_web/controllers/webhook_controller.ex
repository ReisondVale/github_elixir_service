defmodule GithubElixirServiceWeb.WebhookController do
  @moduledoc """
  This controller handles requests related to GitHub webhook integration.

  It schedules a job using Oban to fetch data from GitHub (such as issues and contributors)

  The job is scheduled to run 24 hours after the request is received, ensuring asynchronous
  processing and flexibility in webhook delivery.
  """

  use GithubElixirServiceWeb, :controller

  alias GithubElixirService.ObanWorker.WebhookWorker

  @spec fetch_data_issues(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def fetch_data_issues(conn, %{"user" => user, "repository" => repo}) do
    %{
      "user" => user,
      "repository" => repo
    }
    |> WebhookWorker.new()
    |> Oban.insert(schedule_in: 24 * 60 * 60)

    json(conn, %{message: "Github data issues is being sent to Webhook.site"})
  end
end
