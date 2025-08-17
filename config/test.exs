import Config

# Test configuration
config :ex_hospitable,
  # Disable external HTTP calls in tests
  http_adapter: HospitableClient.HTTP.MockAdapter

# Configure logger for tests
config :logger,
  level: :warning

# Use a shorter timeout for tests
config :httpoison,
  timeout: 5_000,
  recv_timeout: 5_000
