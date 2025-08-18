defmodule HospitableClient do
  @moduledoc """
  Elixir client library for Hospitable Public API.

  This library provides a convenient interface for interacting with the
  Hospitable Public API v2, including authentication management and
  HTTP request handling.

  ## Configuration

  The client can be configured using environment variables in a `.env` file:

      HOSPITABLE_ACCESS_TOKEN=your_personal_access_token_here
      HOSPITABLE_BASE_URL=https://public.api.hospitable.com/v2
      HOSPITABLE_TIMEOUT=30000
      HOSPITABLE_RECV_TIMEOUT=30000

  ## Usage

      # Set authentication token
      HospitableClient.set_token("your_access_token")

      # Make API requests
      {:ok, properties} = HospitableClient.get("/properties")

  ## Authentication

  This library supports Personal Access Token (PAT) authentication.
  OAuth2 support may be added in future versions.
  """

  alias HospitableClient.Auth.Manager, as: AuthManager
  alias HospitableClient.HTTP.Client
  alias HospitableClient.Properties

  @doc """
  Sets the authentication token for API requests.

  ## Examples

      iex> HospitableClient.set_token("your_access_token")
      :ok

  """
  @spec set_token(String.t()) :: :ok | {:error, term()}
  def set_token(token) when is_binary(token) do
    AuthManager.set_token(token)
  end

  @doc """
  Gets the current authentication token.

  ## Examples

      iex> HospitableClient.get_token()
      {:ok, "your_access_token"}

      iex> HospitableClient.get_token()
      {:error, :no_token}

  """
  @spec get_token() :: {:ok, String.t()} | {:error, :no_token}
  def get_token do
    AuthManager.get_token()
  end

  @doc """
  Checks if the client is authenticated.

  ## Examples

      iex> HospitableClient.authenticated?()
      true

  """
  @spec authenticated?() :: boolean()
  def authenticated? do
    case get_token() do
      {:ok, _token} -> true
      {:error, _} -> false
    end
  end

  @doc """
  Makes a GET request to the Hospitable API.

  ## Examples

      iex> HospitableClient.get("/properties")
      {:ok, %{"data" => [...]}}

      iex> HospitableClient.get("/properties", %{"include" => "calendar"})
      {:ok, %{"data" => [...], "included" => [...]}}

  """
  @spec get(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def get(path, params \\ %{}) do
    Client.get(path, params)
  end

  @doc """
  Makes a POST request to the Hospitable API.

  ## Examples

      iex> HospitableClient.post("/properties", %{"name" => "My Property"})
      {:ok, %{"data" => %{"id" => "123", "name" => "My Property"}}}

  """
  @spec post(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def post(path, body) do
    Client.post(path, body)
  end

  @doc """
  Makes a PUT request to the Hospitable API.

  ## Examples

      iex> HospitableClient.put("/properties/123", %{"name" => "Updated Property"})
      {:ok, %{"data" => %{"id" => "123", "name" => "Updated Property"}}}

  """
  @spec put(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def put(path, body) do
    Client.put(path, body)
  end

  @doc """
  Makes a PATCH request to the Hospitable API.

  ## Examples

      iex> HospitableClient.patch("/properties/123", %{"name" => "Partially Updated"})
      {:ok, %{"data" => %{"id" => "123", "name" => "Partially Updated"}}}

  """
  @spec patch(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def patch(path, body) do
    Client.patch(path, body)
  end

  @doc """
  Makes a DELETE request to the Hospitable API.

  ## Examples

      iex> HospitableClient.delete("/properties/123")
      {:ok, %{}}

  """
  @spec delete(String.t()) :: {:ok, map()} | {:error, term()}
  def delete(path) do
    Client.delete(path)
  end

  ## Properties API

  @doc """
  Retrieves a paginated list of properties.

  This is a convenience function that delegates to `HospitableClient.Properties.get_properties/1`.
  For more advanced property operations, use the `HospitableClient.Properties` module directly.

  ## Available Include Options

  - `"user"` - Include property owner information
  - `"listings"` - Include platform listings (requires listing:read scope)
  - `"details"` - Include detailed property information  
  - `"bookings"` - Include booking policies and rules

  Multiple includes can be combined: `"user,listings,details,bookings"`

  ## Examples

      iex> HospitableClient.get_properties()
      {:ok, %{"data" => [...], "meta" => %{"total" => 45}}}

      iex> HospitableClient.get_properties(%{page: 2, per_page: 25})
      {:ok, %{"data" => [...], "meta" => %{"current_page" => 2}}}

      iex> HospitableClient.get_properties(%{include: "user,listings,details"})
      {:ok, %{"data" => [...], "included" => [...]}}

  """
  @spec get_properties(map()) :: {:ok, map()} | {:error, term()}
  def get_properties(opts \\ %{}) do
    Properties.get_properties(opts)
  end

  @doc """
  Retrieves a single property by UUID.

  This is a convenience function that delegates to `HospitableClient.Properties.get_property/2`.

  ## Parameters

  - `property_uuid` - Valid UUID string for the property
  - `opts` - Optional map with include options

  ## Examples

      iex> HospitableClient.get_property("550e8400-e29b-41d4-a716-446655440000")
      {:ok, %{"id" => "550e8400-e29b-41d4-a716-446655440000", ...}}

      iex> HospitableClient.get_property("550e8400-e29b-41d4-a716-446655440000", %{include: "user,listings"})
      {:ok, %{"id" => "...", "user" => %{...}, "listings" => [...]}}

  ## Errors

      iex> HospitableClient.get_property("invalid-uuid")
      {:error, :invalid_uuid}

      iex> HospitableClient.get_property("550e8400-e29b-41d4-a716-446655440000")
      {:error, {:not_found, %{"message" => "Property not found"}}}

  """
  @spec get_property(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def get_property(property_uuid, opts \\ %{}) do
    Properties.get_property(property_uuid, opts)
  end
end
