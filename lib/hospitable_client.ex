defmodule HospitableClient do
  @moduledoc """
  A client library for the Hospitable API.
  
  This module provides authentication and configuration for making requests
  to the Hospitable API endpoints.
  """


  defmodule Auth do
    @moduledoc """
    Handles authentication for the Hospitable API.
    """

    @type api_key :: String.t()
    @type headers :: [{String.t(), String.t()}]

    @doc """
    Creates authentication headers for API requests.

    ## Parameters
    - `api_key`: The API key for authentication

    ## Examples

        iex> HospitableClient.Auth.headers("your-api-key")
        [{"Authorization", "Bearer your-api-key"}, {"Content-Type", "application/json"}]

    """
    @spec headers(api_key()) :: headers()
    def headers(api_key) when is_binary(api_key) do
      [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]
    end

    @doc """
    Validates that an API key is present and properly formatted.

    ## Parameters
    - `api_key`: The API key to validate

    ## Examples

        iex> HospitableClient.Auth.valid_api_key?("sk_test_123")
        true

        iex> HospitableClient.Auth.valid_api_key?("")
        false

        iex> HospitableClient.Auth.valid_api_key?(nil)
        false

    """
    @spec valid_api_key?(any()) :: boolean()
    def valid_api_key?(api_key) when is_binary(api_key) and byte_size(api_key) > 0, do: true
    def valid_api_key?(_), do: false
  end

  defmodule Config do
    @moduledoc """
    Configuration management for the Hospitable client.
    """

    @default_base_url "https://api.hospitable.com"

    @type config :: %{
            api_key: String.t(),
            base_url: String.t()
          }

    @doc """
    Creates a new configuration with the provided API key.

    ## Parameters
    - `api_key`: The Hospitable API key
    - `opts`: Optional configuration overrides

    ## Examples

        iex> HospitableClient.Config.new("your-api-key")
        %{api_key: "your-api-key", base_url: "https://api.hospitable.com"}

    """
    @spec new(String.t(), keyword()) :: config()
    def new(api_key, opts \\ []) do
      unless Auth.valid_api_key?(api_key) do
        raise ArgumentError, "API key must be a non-empty string"
      end

      %{
        api_key: api_key,
        base_url: Keyword.get(opts, :base_url, @default_base_url)
      }
    end

    @doc """
    Gets the API key from application config or environment variable.
    
    Checks for configuration in this order:
    1. Application config: `config :ex_hospitable, api_key: "..."`
    2. Environment variable: `HOSPITABLE_API_KEY`

    ## Examples

        iex> Application.put_env(:ex_hospitable, :api_key, "test-key")
        iex> HospitableClient.Config.get_api_key()
        "test-key"

    """
    @spec get_api_key() :: {:ok, String.t()} | {:error, :not_found}
    def get_api_key do
      case Application.get_env(:ex_hospitable, :api_key) do
        nil ->
          case System.get_env("HOSPITABLE_API_KEY") do
            nil -> {:error, :not_found}
            key -> {:ok, key}
          end

        key ->
          {:ok, key}
      end
    end
  end

  @doc """
  Creates a new client configuration.

  ## Parameters
  - `api_key`: The Hospitable API key

  ## Examples

      iex> client = HospitableClient.new("your-api-key")
      %{api_key: "your-api-key", base_url: "https://api.hospitable.com"}

  """
  @spec new(String.t()) :: Config.config()
  def new(api_key) do
    Config.new(api_key)
  end

  @doc """
  Creates a new client configuration using API key from config or environment.

  ## Examples

      iex> Application.put_env(:ex_hospitable, :api_key, "test-key")
      iex> {:ok, client} = HospitableClient.from_env()
      {:ok, %{api_key: "test-key", base_url: "https://api.hospitable.com"}}

  """
  @spec from_env() :: {:ok, Config.config()} | {:error, :api_key_not_found}
  def from_env do
    case Config.get_api_key() do
      {:ok, api_key} -> {:ok, Config.new(api_key)}
      {:error, :not_found} -> {:error, :api_key_not_found}
    end
  end

  @doc """
  Gets multiple reservations with optional filtering and pagination.

  If no config is provided, uses the automatically loaded configuration from environment.
  Delegates to `HospitableClient.Reservations.get_reservations/2`.

  ## Examples

      # Using automatic configuration (requires HOSPITABLE_API_KEY env var)
      iex> HospitableClient.get_reservations(
      iex>   include: "financials,guest"
      iex> )
      {:error, :api_key_not_configured}

      # Using manual configuration
      iex> client = HospitableClient.new("api-key")
      iex> client.api_key
      "api-key"

  """
  @spec get_reservations(Config.config() | keyword(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_reservations(config_or_opts \\ [], opts \\ [])
  
  def get_reservations(config, opts) when is_map(config) do
    HospitableClient.Reservations.get_reservations(config, opts)
  end
  
  def get_reservations(opts, []) when is_list(opts) do
    case HospitableClient.Application.get_client_config() do
      {:ok, config} -> HospitableClient.Reservations.get_reservations(config, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets a specific reservation by UUID.

  If no config is provided, uses the automatically loaded configuration from environment.
  Delegates to `HospitableClient.Reservations.get_reservation/3`.

  ## Examples

      # Using automatic configuration (requires HOSPITABLE_API_KEY env var)
      iex> HospitableClient.get_reservation(
      iex>   "6f58fd0a-a9cb-3746-9219-384a156ff7bb",
      iex>   include: "financials,guest"
      iex> )
      {:error, :api_key_not_configured}

      # Using manual configuration
      iex> client = HospitableClient.new("api-key")
      iex> client.api_key
      "api-key"

  """
  @spec get_reservation(Config.config() | String.t(), String.t() | keyword(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_reservation(config_or_uuid, uuid_or_opts \\ [], opts \\ [])
  
  def get_reservation(config, uuid, opts) when is_map(config) and is_binary(uuid) do
    HospitableClient.Reservations.get_reservation(config, uuid, opts)
  end
  
  def get_reservation(uuid, opts, []) when is_binary(uuid) and is_list(opts) do
    case HospitableClient.Application.get_client_config() do
      {:ok, config} -> HospitableClient.Reservations.get_reservation(config, uuid, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets all properties with optional pagination and includes.

  If no config is provided, uses the automatically loaded configuration from environment.
  Delegates to `HospitableClient.Properties.get_properties/2`.

  ## Examples

      # Using automatic configuration (requires HOSPITABLE_API_KEY env var)
      iex> HospitableClient.get_properties(
      iex>   page: 1,
      iex>   per_page: 50
      iex> )
      {:error, :api_key_not_configured}

      # Using manual configuration
      iex> client = HospitableClient.new("api-key")
      iex> client.api_key
      "api-key"

  """
  @spec get_properties(Config.config() | keyword(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_properties(config_or_opts \\ [], opts \\ [])
  
  def get_properties(config, opts) when is_map(config) do
    HospitableClient.Properties.get_properties(config, opts)
  end
  
  def get_properties(opts, []) when is_list(opts) do
    case HospitableClient.Application.get_client_config() do
      {:ok, config} -> HospitableClient.Properties.get_properties(config, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Searches for available properties based on dates and guest requirements.

  If no config is provided, uses the automatically loaded configuration from environment.
  Delegates to `HospitableClient.Properties.search_properties/2`.

  ## Examples

      # Using automatic configuration (requires HOSPITABLE_API_KEY env var)
      iex> HospitableClient.search_properties(
      iex>   adults: 2,
      iex>   start_date: "2025-08-16",
      iex>   end_date: "2025-08-21"
      iex> )
      {:error, :api_key_not_configured}

      # Using manual configuration
      iex> client = HospitableClient.new("api-key")
      iex> client.api_key
      "api-key"

  """
  @spec search_properties(Config.config() | keyword(), keyword()) :: {:ok, map()} | {:error, term()}
  def search_properties(config_or_opts \\ [], opts \\ [])
  
  def search_properties(config, opts) when is_map(config) do
    HospitableClient.Properties.search_properties(config, opts)
  end
  
  def search_properties(opts, []) when is_list(opts) do
    case HospitableClient.Application.get_client_config() do
      {:ok, config} -> HospitableClient.Properties.search_properties(config, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets all messages for a specific reservation.

  If no config is provided, uses the automatically loaded configuration from environment.
  Delegates to `HospitableClient.Messages.get_messages/2`.

  ## Examples

      # Using automatic configuration requires HOSPITABLE_API_KEY env var
      iex> is_function(&HospitableClient.get_messages/1)
      true

      # Using manual configuration
      iex> client = HospitableClient.new("api-key")
      iex> client.api_key
      "api-key"

  """
  @spec get_messages(Config.config() | String.t(), String.t() | nil) :: {:ok, map()} | {:error, term()}
  def get_messages(config_or_uuid, reservation_uuid \\ nil)
  
  def get_messages(config, reservation_uuid) when is_map(config) and is_binary(reservation_uuid) do
    HospitableClient.Messages.get_messages(config, reservation_uuid)
  end
  
  def get_messages(reservation_uuid, nil) when is_binary(reservation_uuid) do
    case HospitableClient.Application.get_client_config() do
      {:ok, config} -> HospitableClient.Messages.get_messages(config, reservation_uuid)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Sends a message to a reservation conversation.

  If no config is provided, uses the automatically loaded configuration from environment.
  Delegates to `HospitableClient.Messages.send_message/3`.

  ## Examples

      # Using automatic configuration (requires HOSPITABLE_API_KEY env var)
      iex> HospitableClient.send_message(
      iex>   "becd1474-ccd1-40bf-9ce8-04456bfa338d",
      iex>   body: "Hello, guest!\\nYour check-in is at 3 PM."
      iex> )
      {:error, :api_key_not_configured}

      # Using manual configuration
      iex> client = HospitableClient.new("api-key")
      iex> client.api_key
      "api-key"

  """
  @spec send_message(Config.config() | String.t(), String.t() | keyword(), keyword()) :: {:ok, map()} | {:error, term()}
  def send_message(config_or_uuid, reservation_uuid_or_opts \\ [], opts \\ [])
  
  def send_message(config, reservation_uuid, opts) when is_map(config) and is_binary(reservation_uuid) do
    HospitableClient.Messages.send_message(config, reservation_uuid, opts)
  end
  
  def send_message(reservation_uuid, opts, []) when is_binary(reservation_uuid) and is_list(opts) do
    case HospitableClient.Application.get_client_config() do
      {:ok, config} -> HospitableClient.Messages.send_message(config, reservation_uuid, opts)
      {:error, reason} -> {:error, reason}
    end
  end
end
