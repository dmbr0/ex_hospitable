defmodule HospitableClient.Application do
  @moduledoc """
  The HospitableClient Application.

  This module starts the supervision tree for the Hospitable API client,
  including the authentication manager and other necessary processes.
  """

  use Application

  @impl true
  def start(_type, _args) do
    # Load environment variables from .env file
    load_dotenv()

    children = [
      # Authentication manager
      {HospitableClient.Auth.Manager, []},
      # HTTP client supervisor
      {HospitableClient.HTTP.Supervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HospitableClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Loads environment variables from .env file if it exists.
  defp load_dotenv do
    case File.exists?(".env") do
      true ->
        Dotenv.load()

      false ->
        # Create example .env file
        create_example_env()
    end
  end

  # Creates an example .env file with template variables.
  defp create_example_env do
    content = """
    # Hospitable API Configuration
    HOSPITABLE_ACCESS_TOKEN=your_personal_access_token_here
    HOSPITABLE_BASE_URL=https://public.api.hospitable.com/v2
    
    # Optional: Timeout settings (in milliseconds)
    HOSPITABLE_TIMEOUT=30000
    HOSPITABLE_RECV_TIMEOUT=30000
    """

    File.write(".env.example", content)
  end
end
