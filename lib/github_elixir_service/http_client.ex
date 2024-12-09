defmodule GithubElixirService.HttpClient do
  @moduledoc """
  Defines the behavior for an HTTP client.
  """

  @callback get(String.t(), list()) :: {:ok, HTTPoison.Response.t()} | {:error, any()}
  @callback post(String.t(), String.t(), list()) ::
              {:ok, HTTPoison.Response.t()} | {:error, any()}

  @spec get(String.t(), list()) :: {:ok, HTTPoison.Response.t()} | {:error, any()}
  def get(url, headers), do: impl().get(url, headers)

  @spec post(String.t(), String.t(), list()) :: {:ok, HTTPoison.Response.t()} | {:error, any()}
  def post(url, body, headers), do: impl().post(url, body, headers)

  defp impl, do: Application.get_env(:github_elixir_service, :http_client, HTTPoison)
end
