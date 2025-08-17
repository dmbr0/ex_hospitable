import Config

# Development configuration
config :ex_hospitable,
  # Enable debug logging in development
  debug: true

# Configure logger for development
config :logger,
  level: :debug

# Configure HTTPoison for development (if needed)
config :httpoison,
  timeout: 30_000,
  recv_timeout: 30_000
