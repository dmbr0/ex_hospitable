defmodule HospitableClient.Auth.Manager do
  @moduledoc """
  GenServer for managing authentication state and token lifecycle.

  This module provides centralized authentication management for the
  Hospitable API client, including token storage, validation, and
  lifecycle management.
  """

  use GenServer
  require Logger

  alias HospitableClient.Auth.Records
  require Records

  @name __MODULE__
  @validation_interval :timer.minutes(15)
  @max_validation_attempts 3

  # Client API

  @doc """
  Starts the authentication manager.
  """
  @spec start_link(list()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @doc """
  Sets the authentication token.

  ## Examples

      iex> HospitableClient.Auth.Manager.set_token("pat_123456789")
      :ok

  """
  @spec set_token(String.t()) :: :ok | {:error, term()}
  def set_token(token) when is_binary(token) do
    GenServer.call(@name, {:set_token, token})
  end

  @doc """
  Gets the current authentication token.

  ## Examples

      iex> HospitableClient.Auth.Manager.get_token()
      {:ok, "pat_123456789"}

      iex> HospitableClient.Auth.Manager.get_token()
      {:error, :no_token}

  """
  @spec get_token() :: {:ok, String.t()} | {:error, :no_token}
  def get_token do
    GenServer.call(@name, :get_token)
  end

  @doc """
  Gets the current authentication credentials.

  ## Examples

      iex> HospitableClient.Auth.Manager.get_credentials()
      {:ok, auth_credentials(...)}

  """
  @spec get_credentials() :: {:ok, Records.auth_credentials()} | {:error, :no_credentials}
  def get_credentials do
    GenServer.call(@name, :get_credentials)
  end

  @doc """
  Checks if the client is currently authenticated.

  ## Examples

      iex> HospitableClient.Auth.Manager.authenticated?()
      true

  """
  @spec authenticated?() :: boolean()
  def authenticated? do
    GenServer.call(@name, :authenticated?)
  end

  @doc """
  Validates the current token with the API.

  ## Examples

      iex> HospitableClient.Auth.Manager.validate_token()
      :ok

      iex> HospitableClient.Auth.Manager.validate_token()
      {:error, :invalid_token}

  """
  @spec validate_token() :: :ok | {:error, term()}
  def validate_token do
    GenServer.call(@name, :validate_token, 30_000)
  end

  @doc """
  Clears the current authentication state.

  ## Examples

      iex> HospitableClient.Auth.Manager.clear_auth()
      :ok

  """
  @spec clear_auth() :: :ok
  def clear_auth do
    GenServer.call(@name, :clear_auth)
  end

  @doc """
  Gets the current authentication state for debugging.

  ## Examples

      iex> HospitableClient.Auth.Manager.get_state()
      auth_state(...)

  """
  @spec get_state() :: Records.auth_state()
  def get_state do
    GenServer.call(@name, :get_state)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Starting HospitableClient Auth Manager")

    # Initialize state
    state = Records.auth_state()

    # Load token from environment if available
    state = load_token_from_env(state)

    # Schedule periodic token validation
    schedule_validation()

    {:ok, state}
  end

  @impl true
  def handle_call({:set_token, token}, _from, state) do
    Logger.info("Setting authentication token")

    credentials =
      Records.auth_credentials(
        token: token,
        token_type: "Bearer",
        created_at: DateTime.utc_now()
      )

    new_state =
      Records.auth_state(state,
        credentials: credentials,
        authenticated: true,
        validation_attempts: 0
      )

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_token, _from, state) do
    case Records.auth_state(state, :credentials) do
      nil ->
        {:reply, {:error, :no_token}, state}

      credentials ->
        token = Records.auth_credentials(credentials, :token)
        {:reply, {:ok, token}, state}
    end
  end

  @impl true
  def handle_call(:get_credentials, _from, state) do
    case Records.auth_state(state, :credentials) do
      nil ->
        {:reply, {:error, :no_credentials}, state}

      credentials ->
        {:reply, {:ok, credentials}, state}
    end
  end

  @impl true
  def handle_call(:authenticated?, _from, state) do
    authenticated = Records.auth_state(state, :authenticated)
    {:reply, authenticated, state}
  end

  @impl true
  def handle_call(:validate_token, _from, state) do
    case validate_token_with_api(state) do
      :ok ->
        new_state =
          Records.auth_state(state,
            authenticated: true,
            last_validated: DateTime.utc_now(),
            validation_attempts: 0
          )

        {:reply, :ok, new_state}

      {:error, reason} ->
        attempts = Records.auth_state(state, :validation_attempts) + 1

        new_state =
          if attempts >= @max_validation_attempts do
            Logger.warning("Token validation failed #{attempts} times, marking as unauthenticated")

            Records.auth_state(state,
              authenticated: false,
              validation_attempts: attempts
            )
          else
            Records.auth_state(state, validation_attempts: attempts)
          end

        {:reply, {:error, reason}, new_state}
    end
  end

  @impl true
  def handle_call(:clear_auth, _from, _state) do
    Logger.info("Clearing authentication state")
    new_state = Records.auth_state()
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:validate_token, state) do
    # Periodic token validation
    case Records.auth_state(state, :credentials) do
      nil ->
        schedule_validation()
        {:noreply, state}

      _credentials ->
        case validate_token_with_api(state) do
          :ok ->
            new_state =
              Records.auth_state(state,
                authenticated: true,
                last_validated: DateTime.utc_now(),
                validation_attempts: 0
              )

            schedule_validation()
            {:noreply, new_state}

          {:error, reason} ->
            Logger.warning("Periodic token validation failed: #{inspect(reason)}")
            attempts = Records.auth_state(state, :validation_attempts) + 1

            new_state =
              if attempts >= @max_validation_attempts do
                Logger.error("Token validation failed #{attempts} times, marking as unauthenticated")

                Records.auth_state(state,
                  authenticated: false,
                  validation_attempts: attempts
                )
              else
                Records.auth_state(state, validation_attempts: attempts)
              end

            schedule_validation()
            {:noreply, new_state}
        end
    end
  end

  # Private Functions

  defp load_token_from_env(state) do
    case System.get_env("HOSPITABLE_ACCESS_TOKEN") do
      nil ->
        Logger.info("No HOSPITABLE_ACCESS_TOKEN found in environment")
        state

      token when is_binary(token) and token != "" ->
        Logger.info("Loading authentication token from environment")

        credentials =
          Records.auth_credentials(
            token: token,
            token_type: "Bearer",
            created_at: DateTime.utc_now()
          )

        Records.auth_state(state,
          credentials: credentials,
          authenticated: true
        )

      _ ->
        Logger.warning("Invalid HOSPITABLE_ACCESS_TOKEN in environment")
        state
    end
  end

  defp validate_token_with_api(state) do
    case Records.auth_state(state, :credentials) do
      nil ->
        {:error, :no_token}

      credentials ->
        token = Records.auth_credentials(credentials, :token)

        # Make a simple API call to validate the token
        case make_validation_request(token) do
          {:ok, _response} ->
            :ok

          {:error, %HTTPoison.Response{status_code: 401}} ->
            {:error, :invalid_token}

          {:error, %HTTPoison.Response{status_code: 403}} ->
            {:error, :forbidden}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp make_validation_request(token) do
    base_url = System.get_env("HOSPITABLE_BASE_URL", "https://public.api.hospitable.com/v2")
    url = "#{base_url}/properties"

    headers = [
      {"Accept", "application/json"},
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    options = [
      timeout: String.to_integer(System.get_env("HOSPITABLE_TIMEOUT", "30000")),
      recv_timeout: String.to_integer(System.get_env("HOSPITABLE_RECV_TIMEOUT", "30000"))
    ]

    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: status} = response} when status in 200..299 ->
        {:ok, response}

      {:ok, response} ->
        {:error, response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp schedule_validation do
    Process.send_after(self(), :validate_token, @validation_interval)
  end
end
