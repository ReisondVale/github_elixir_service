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
  - A tuple with :ok and a map containing issues and contributors data.
  """
  @spec get_issues_and_contributors(String.t(), String.t(), String.t() | nil) ::
          {:ok,
           %{
             user: String.t(),
             repository: String.t(),
             issues: list(),
             contributors: list()
           }}
          | {:error, any()}
  def get_issues_and_contributors(user, repo, token \\ nil) do
    with {:ok, headers} <- build_headers(token),
         {:ok, issues} <- get_issues(user, repo, headers),
         {:ok, contributors} = get_contributors(user, repo, headers) do
      {:ok,
       %{
         user: user,
         repository: repo,
         issues: issues,
         contributors: contributors
       }}
    else
      {:error, reason} ->
        Logger.error("Failed to get issues and contributors from GitHub: #{inspect(reason)}")
        {:error, "Failed to get issues and contributors"}
    end
  end

  defp build_headers(nil), do: {:ok, [{"Content-Type", "application/json"}]}

  defp build_headers(token),
    do: {:ok, [{"Content-Type", "application/json"}, {"Authorization", "Bearer #{token}"}]}

  defp get_issues(user, repo, headers) do
    url = "#{@api_url}/repos/#{user}/#{repo}/issues"

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HttpClient.get(url, headers),
         {:ok, decoded_body} <- Jason.decode(body),
         issues <- map_issues(decoded_body) do
      {:ok, issues}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_contributors(user, repo, headers) do
    url = "#{@api_url}/repos/#{user}/#{repo}/contributors"

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HttpClient.get(url, headers),
         {:ok, decoded_body} <- Jason.decode(body),
         contributors <- map_contributors(decoded_body) do
      {:ok, contributors}
    else
      {:error, reason} ->
        {:error, reason}
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
