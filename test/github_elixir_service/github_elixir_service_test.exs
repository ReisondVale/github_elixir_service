defmodule GithubElixirService.GithubClientTest do
  use ExUnit.Case, async: true
  import Mox

  alias GithubElixirService.GithubClient

  @user "valid_user"
  @repo "valid_repo"
  @title_issue "Test Issue"
  @author_issue "reisondvale"

  setup :verify_on_exit!

  test "returns issues and contributors when the response is 200" do
    Mox.expect(GithubElixirService.MockHttpClient, :get, fn
      "https://api.github.com/repos/valid_user/valid_repo/issues", _headers ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body:
             Jason.encode!([
               %{
                 "title" => "Test Issue",
                 "user" => %{"login" => @author_issue},
                 "labels" => []
               }
             ])
         }}
    end)

    Mox.expect(GithubElixirService.MockHttpClient, :get, fn
      "https://api.github.com/repos/valid_user/valid_repo/contributors", _headers ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body:
             Jason.encode!([
               %{
                 "login" => @author_issue,
                 "id" => 12345,
                 "contributions" => 50
               }
             ])
         }}
    end)

    result = GithubClient.get_issues_and_contributors(@user, @repo)

    assert %{
             user: @user,
             repository: @repo,
             issues: issues,
             contributors: contributors
           } = result

    assert length(issues) > 0

    assert issues == [
             %{
               title: @title_issue,
               author: @author_issue,
               labels: []
             }
           ]

    assert contributors == [
             %{
               name: @author_issue,
               user: 12345,
               qtd_commits: 50
             }
           ]
  end

  test "returns an error when the response is not 200" do
    Mox.expect(GithubElixirService.MockHttpClient, :get, fn
      "https://api.github.com/repos/valid_user/valid_repo/issues", _headers ->
        {:error, :not_found}
    end)

    Mox.expect(GithubElixirService.MockHttpClient, :get, fn
      "https://api.github.com/repos/valid_user/valid_repo/contributors", _headers ->
        {:error, :not_found}
    end)

    result = GithubClient.get_issues_and_contributors(@user, @repo)

    assert %{
             user: @user,
             repository: @repo,
             issues: {:error, "Failed to get issues"},
             contributors: {:error, "Failed to get contributors"}
           } = result
  end

  test "returns an empty list when the repository has no issues" do
    Mox.expect(GithubElixirService.MockHttpClient, :get, fn
      "https://api.github.com/repos/valid_user/valid_repo/issues", _headers ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Jason.encode!([])
         }}
    end)

    Mox.expect(GithubElixirService.MockHttpClient, :get, fn
      "https://api.github.com/repos/valid_user/valid_repo/contributors", _headers ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body:
             Jason.encode!([
               %{
                 "login" => @author_issue,
                 "id" => 12345,
                 "contributions" => 50
               }
             ])
         }}
    end)

    result = GithubClient.get_issues_and_contributors(@user, @repo)

    assert %{
             user: @user,
             repository: @repo,
             issues: issues,
             contributors: contributors
           } = result

    assert length(issues) == 0

    assert contributors == [
             %{
               name: @author_issue,
               user: 12345,
               qtd_commits: 50
             }
           ]
  end
end
