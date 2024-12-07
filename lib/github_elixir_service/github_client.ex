defmodule GithubElixirService.GithubClient do
  @moduledoc """
  This module is responsible for fetching issues and contributors from a specified GitHub user and repository.
  """
  require Logger

  alias GithubElixirService.HttpClient

  @api_url "https://api.github.com"

  @doc """
  ## Parameters
  - `user`: The username or organization that owns the repository.
  - `repo`: The name of the repository.
  - `token` (optional): An authentication token for the GitHub API.
    - If a `token` is provided, it will be used for authenticated requests, allowing access to private repositories and higher rate limits.
    - If no `token` is provided, the request will be made without authentication,
      which may result in stricter rate limits and access only to public repositories.

  ## Returns
  - A map containing issues and contributors data.
  """
  @spec get_issues_and_contributors(String.t(), String.t(), String.t() | nil) :: %{
          user: String.t(),
          repository: String.t(),
          issues: list(),
          contributors: list()
        }
  def get_issues_and_contributors(user, repo, token \\ nil) do
    # adicionar um with para caso de erro em algumas das chamadas
    headers = build_headers(token)
    issues = get_issues(user, repo, headers)
    contributors = get_contributors(user, repo, headers)

    %{
      user: user,
      repository: repo,
      issues: issues,
      contributors: contributors
    }
  end

  defp build_headers(nil), do: [{"Content-Type", "application/json"}]

  defp build_headers(token),
    do: [{"Content-Type", "application/json"}, {"Authorization", "Bearer #{token}"}]

  defp get_issues(user, repo, headers) do
    url = "#{@api_url}/repos/#{user}/#{repo}/issues"

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HttpClient.get(url, headers),
         {:ok, decoded_body} <- decode_body(body),
         issues <- map_issues(decoded_body) do
      issues
    else
      {:error, :unexpected_format} ->
        raise "Unexpected response format"

      {:error, reason} ->
        Logger.error("Failed to get issues from GitHub: #{inspect(reason)}")
        {:error, "Failed to get issues"}
    end
  end

  defp get_contributors(user, repo, headers) do
    url = "#{@api_url}/repos/#{user}/#{repo}/contributors"

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HttpClient.get(url, headers),
         {:ok, decoded_body} <- decode_body(body),
         contributors <- map_contributors(decoded_body) do
      contributors
    else
      {:error, :unexpected_format} ->
        raise "Unexpected response format"

      {:error, reason} ->
        Logger.error("Failed to get contributors from GitHub: #{inspect(reason)}")
        {:error, "Failed to get contributors"}
    end
  end

  defp decode_body(body) do
    case Jason.decode(body) do
      {:ok, []} -> {:ok, []}
      {:ok, data} when is_list(data) -> {:ok, data}
      _ -> {:error, :unexpected_format}
    end
  end

  defp map_issues(issues) do
    Enum.map(issues, fn issue ->
      %{
        title: issue["title"],
        author: issue["user"]["login"],
        labels: Enum.map(issue["labels"], & &1["name"])
      }
    end)
  end

  defp map_contributors(contributors) do
    Enum.map(contributors, fn contributor ->
      %{
        name: contributor["login"],
        user: contributor["id"],
        qtd_commits: contributor["contributions"]
      }
    end)
  end
end
