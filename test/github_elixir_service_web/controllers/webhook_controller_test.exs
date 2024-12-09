defmodule GithubElixirServiceWeb.Controllers.WebhookControllerTest do
  use GithubElixirServiceWeb.ConnCase, async: true

  alias GithubElixirService.Repo

  describe "fetch_data_issues/2" do
    test "successfully schedules a job", %{conn: conn} do
      Mox.expect(GithubElixirService.MockHttpClient, :get, fn
        "https://api.github.com/repos/reisondvale/valid_repo/issues", _headers ->
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
        "https://api.github.com/repos/reisondvale/valid_repo/contributors", _headers ->
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

      Mox.expect(GithubElixirService.MockHttpClient, :post, fn _url, _body, _headers ->

        {:ok, %HTTPoison.Response{status_code: 200}}
      end)

      params = %{"user" => "reisondvale", "repository" => "valid_repo"}

      conn = post(conn, ~p"/fetch_issues", params)

      assert json_response(conn, 200)["message"] == "Webhook will be sent in 24 hours"

      job = Repo.one!(Oban.Job)

      assert job.state == "scheduled"
      assert job.queue == "default"
      assert job.worker == "GithubElixirService.ObanWorker.WebhookWorker"
      assert job.args["body"]
    end

    test "returns an error when scheduling fails", %{conn: conn} do
      Mox.expect(GithubElixirService.MockHttpClient, :get, fn
        "https://api.github.com/repos/invalid_user/invalid_repo/issues", _headers ->
          {:error, :not_found}
      end)

      params = %{"user" => "invalid_user", "repository" => "invalid_repo"}

      conn = post(conn, ~p"/fetch_issues", params)

      assert json_response(conn, 500)["message"] == "Error scheduling webhook"

      assert Repo.aggregate(Oban.Job, :count, :id) == 0
    end
  end
end
