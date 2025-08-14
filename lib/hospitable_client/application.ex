defmodule HospitableClient.Application do
  @moduledoc """
  Application module for HospitableClient.
  
  Handles initialization and configuration loading at startup.
  """

  use Application

  def start(_type, _args) do
    children = []

    # Load and validate configuration at startup
    load_configuration()

    opts = [strategy: :one_for_one, name: HospitableClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Loads API key configuration from environment and stores it in application environment.
  """
  def load_configuration do
    case Application.get_env(:ex_hospitable, :api_key) do
      nil ->
        # No API key configured, but don't crash - allow runtime configuration
        :ok

      api_key when is_binary(api_key) and byte_size(api_key) > 0 ->
        # Store validated configuration
        base_url = Application.get_env(:ex_hospitable, :base_url, "https://api.hospitable.com")
        
        config = %{
          api_key: api_key,
          base_url: base_url
        }
        
        Application.put_env(:ex_hospitable, :client_config, config)
        :ok

      _ ->
        # Invalid API key configured
        :ok
    end
  end

  @doc """
  Gets the current client configuration from application environment.
  
  Returns the configuration that was loaded at startup, or attempts to
  load it from environment if not already loaded.
  """
  def get_client_config do
    case Application.get_env(:ex_hospitable, :client_config) do
      nil ->
        # Try to load configuration on demand
        case HospitableClient.Config.get_api_key() do
          {:ok, api_key} ->
            base_url = Application.get_env(:ex_hospitable, :base_url, "https://api.hospitable.com")
            config = HospitableClient.Config.new(api_key, base_url: base_url)
            Application.put_env(:ex_hospitable, :client_config, config)
            {:ok, config}
          
          {:error, :not_found} ->
            {:error, :api_key_not_configured}
        end
      
      config ->
        {:ok, config}
    end
  end
end