defmodule HospitableClient.HTTP.Client do
  @moduledoc """
  HTTP client for making requests to the Hospitable API.

  This module handles HTTP requests, authentication integration,
  and response processing for the Hospitable Public API.
  """

  require Logger

  alias HospitableClient.Auth.Manager, as: AuthManager
  alias HospitableClient.Auth.Records
  require Records

  @base_url_env "HOSPITABLE_BASE_URL"
  @default_base_url "https://public.api.hospitable.com/v2"
  @timeout_env "HOSPITABLE_TIMEOUT"
  @recv_timeout_env "HOSPITABLE_RECV_TIMEOUT"
  @default_timeout 30_000

  @doc """
  Makes a GET request to the Hospitable API.

  ## Parameters

  - `path`: API endpoint path (e.g., "/properties")
  - `params`: Query parameters as a map (optional)

  ## Examples

      iex> HospitableClient.HTTP.Client.get("/properties")
      {:ok, %{"data" => [...]}}

      iex> HospitableClient.HTTP.Client.get("/properties", %{"include" => "calendar"})
      {:ok, %{"data" => [...], "included" => [...]}}

  """
  @spec get(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def get(path, params \\ %{}) do
    url = build_url(path, params)

    with {:ok, headers} <- build_headers(),
         {:ok, response} <- make_request(:get, url, "", headers),
         {:ok, body} <- parse_response(response) do
      {:ok, body}
    end
  end

  @doc """
  Makes a POST request to the Hospitable API.

  ## Parameters

  - `path`: API endpoint path
  - `body`: Request body as a map

  ## Examples

      iex> HospitableClient.HTTP.Client.post("/properties", %{"name" => "My Property"})
      {:ok, %{"data" => %{"id" => "123", "name" => "My Property"}}}

  """
  @spec post(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def post(path, body) do
    url = build_url(path)

    with {:ok, json_body} <- encode_body(body),
         {:ok, headers} <- build_headers(),
         {:ok, response} <- make_request(:post, url, json_body, headers),
         {:ok, response_body} <- parse_response(response) do
      {:ok, response_body}
    end
  end

  @doc """
  Makes a PUT request to the Hospitable API.

  ## Parameters

  - `path`: API endpoint path
  - `body`: Request body as a map

  ## Examples

      iex> HospitableClient.HTTP.Client.put("/properties/123", %{"name" => "Updated Property"})
      {:ok, %{"data" => %{"id" => "123", "name" => "Updated Property"}}}

  """
  @spec put(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def put(path, body) do
    url = build_url(path)

    with {:ok, json_body} <- encode_body(body),
         {:ok, headers} <- build_headers(),
         {:ok, response} <- make_request(:put, url, json_body, headers),
         {:ok, response_body} <- parse_response(response) do
      {:ok, response_body}
    end
  end

  @doc """
  Makes a PATCH request to the Hospitable API.

  ## Parameters

  - `path`: API endpoint path
  - `body`: Request body as a map

  ## Examples

      iex> HospitableClient.HTTP.Client.patch("/properties/123", %{"name" => "Partially Updated"})
      {:ok, %{"data" => %{"id" => "123", "name" => "Partially Updated"}}}

  """
  @spec patch(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def patch(path, body) do
    url = build_url(path)

    with {:ok, json_body} <- encode_body(body),
         {:ok, headers} <- build_headers(),
         {:ok, response} <- make_request(:patch, url, json_body, headers),
         {:ok, response_body} <- parse_response(response) do
      {:ok, response_body}
    end
  end

  @doc """
  Makes a DELETE request to the Hospitable API.

  ## Parameters

  - `path`: API endpoint path

  ## Examples

      iex> HospitableClient.HTTP.Client.delete("/properties/123")
      {:ok, %{}}

  """
  @spec delete(String.t()) :: {:ok, map()} | {:error, term()}
  def delete(path) do
    url = build_url(path)

    with {:ok, headers} <- build_headers(),
         {:ok, response} <- make_request(:delete, url, "", headers),
         {:ok, body} <- parse_response(response) do
      {:ok, body}
    end
  end

  # Private Functions

  defp build_url(path, params \\ %{}) do
    base_url = System.get_env(@base_url_env, @default_base_url)
    clean_path = String.trim_leading(path, "/")
    url = "#{base_url}/#{clean_path}"

    case Enum.empty?(params) do
      true -> url
      false -> url <> "?" <> URI.encode_query(params)
    end
  end

  defp build_headers do
    case AuthManager.get_credentials() do
      {:ok, credentials} ->
        token = Records.auth_credentials(credentials, :token)
        token_type = Records.auth_credentials(credentials, :token_type)

        headers = [
          {"Accept", "application/json"},
          {"Content-Type", "application/json"},
          {"Authorization", "#{token_type} #{token}"}
        ]

        {:ok, headers}

      {:error, :no_credentials} ->
        Logger.error("No authentication credentials available")
        {:error, :no_credentials}
    end
  end

  defp encode_body(body) when is_map(body) do
    case Jason.encode(body) do
      {:ok, json} -> {:ok, json}
      {:error, reason} -> {:error, {:json_encode_error, reason}}
    end
  end

  defp make_request(method, url, body, headers) do
    options = [
      timeout: get_timeout(),
      recv_timeout: get_recv_timeout(),
      follow_redirect: true,
      max_redirect: 3
    ]

    Logger.debug("Making #{method} request to #{url}")

    case HTTPoison.request(method, url, body, headers, options) do
      {:ok, response} ->
        Logger.debug("Received response with status #{response.status_code}")
        {:ok, response}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, {:http_error, reason}}

      {:error, reason} ->
        Logger.error("Unexpected error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_response(%HTTPoison.Response{status_code: status, body: body}) 
       when status in 200..299 do
    case body do
      "" ->
        {:ok, %{}}

      json_body ->
        case Jason.decode(json_body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
        end
    end
  end

  defp parse_response(%HTTPoison.Response{status_code: 401, body: body}) do
    Logger.warning("Authentication failed (401)")

    case Jason.decode(body) do
      {:ok, error_data} -> {:error, {:unauthorized, error_data}}
      {:error, _} -> {:error, {:unauthorized, %{"message" => "Authentication failed"}}}
    end
  end

  defp parse_response(%HTTPoison.Response{status_code: 403, body: body}) do
    Logger.warning("Access forbidden (403)")

    case Jason.decode(body) do
      {:ok, error_data} -> {:error, {:forbidden, error_data}}
      {:error, _} -> {:error, {:forbidden, %{"message" => "Access forbidden"}}}
    end
  end

  defp parse_response(%HTTPoison.Response{status_code: 404, body: body}) do
    Logger.warning("Resource not found (404)")

    case Jason.decode(body) do
      {:ok, error_data} -> {:error, {:not_found, error_data}}
      {:error, _} -> {:error, {:not_found, %{"message" => "Resource not found"}}}
    end
  end

  defp parse_response(%HTTPoison.Response{status_code: status, body: body}) 
       when status in 400..499 do
    Logger.warning("Client error (#{status})")

    case Jason.decode(body) do
      {:ok, error_data} -> {:error, {:client_error, status, error_data}}
      {:error, _} -> {:error, {:client_error, status, %{"message" => "Client error"}}}
    end
  end

  defp parse_response(%HTTPoison.Response{status_code: status, body: body}) 
       when status in 500..599 do
    Logger.error("Server error (#{status})")

    case Jason.decode(body) do
      {:ok, error_data} -> {:error, {:server_error, status, error_data}}
      {:error, _} -> {:error, {:server_error, status, %{"message" => "Server error"}}}
    end
  end

  defp parse_response(%HTTPoison.Response{status_code: status, body: body}) do
    Logger.warning("Unexpected status code (#{status})")

    case Jason.decode(body) do
      {:ok, error_data} -> {:error, {:unexpected_status, status, error_data}}
      {:error, _} -> {:error, {:unexpected_status, status, %{"message" => "Unexpected response"}}}
    end
  end

  defp get_timeout do
    @timeout_env
    |> System.get_env(Integer.to_string(@default_timeout))
    |> String.to_integer()
  end

  defp get_recv_timeout do
    @recv_timeout_env
    |> System.get_env(Integer.to_string(@default_timeout))
    |> String.to_integer()
  end
end
