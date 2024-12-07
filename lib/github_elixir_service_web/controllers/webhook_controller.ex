defmodule GithubElixirServiceWeb.WebhookController do
  @moduledoc """
  This controller handles requests related to GitHub webhook integration.

  It processes incoming payloads from GitHub and sends relevant data, such as issues and contributors,
  to a specified webhook URL.
  """

  use GithubElixirServiceWeb, :controller

  alias GithubElixirService.GithubClient

  @spec fetch_data_issues(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def fetch_data_issues(conn, %{"user" => user, "repository" => repo}) do
    webhook_url = System.get_env("WEBHOOK_URL")
    payload = GithubClient.get_issues_and_contributors(user, repo)

    send_to_webhook(webhook_url, payload)

    json(conn, %{message: "Github data issues is being sent to Webhook.site"})
  end

  defp send_to_webhook(url, payload) do
    headers = [{"Content-Type", "application/json"}]
    body = Jason.encode!(payload)

    HTTPoison.post(url, body, headers)
  end
end
