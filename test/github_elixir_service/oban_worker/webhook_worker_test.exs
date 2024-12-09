defmodule GithubElixirService.ObanWorker.WebhookWorkerTest do
  use GithubElixirService.DataCase, async: true

  import Mox

  alias GithubElixirService.ObanWorker.WebhookWorker

  @valid_body Jason.encode!(%{
                user: "valid_user",
                repository: "valid_repo",
                issues: [
                  %{
                    title: "Test Issue",
                    author: "reisondvale",
                    labels: []
                  }
                ],
                contributors: [
                  %{
                    name: "reisondvale",
                    user: 12345,
                    qtd_commits: 50
                  }
                ]
              })

  setup :verify_on_exit!

  describe "perform/1" do
    test "successfully perform a job" do
      Mox.expect(GithubElixirService.MockHttpClient, :post, fn _url, body, _headers ->
        expected_body = @valid_body

        assert body == expected_body
        {:ok, %HTTPoison.Response{status_code: 200}}
      end)

      assert :ok ==
               WebhookWorker.perform(%Oban.Job{args: %{"body" => @valid_body}})
    end

    test "handles errors from post request" do
      Mox.expect(GithubElixirService.MockHttpClient, :post, fn _url, _body, _headers ->
        {:error, %HTTPoison.Error{reason: :timeout}}
      end)

      assert {:error, %HTTPoison.Error{reason: :timeout}} ==
               WebhookWorker.perform(%Oban.Job{args: %{"body" => @valid_body}})
    end
  end

  describe "schedule/2" do
    test "successfully schedule a job" do
      Mox.expect(GithubElixirService.MockHttpClient, :get, fn
        "https://api.github.com/repos/valid_user/valid_repo/issues", _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body:
               Jason.encode!([
                 %{
                   "title" => "Test Issue",
                   "user" => %{"login" => "reisondvale"},
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
                   "login" => "reisondvale",
                   "id" => 12345,
                   "contributions" => 50
                 }
               ])
           }}
      end)

      {:ok, job} = WebhookWorker.schedule("valid_user", "valid_repo")

      assert job.state == "scheduled"
      assert job.args["body"] == @valid_body
    end
  end
end
