import Config

# Production configuration
config :ex_hospitable,
  # Disable debug features in production
  debug: false

# Configure logger for production
config :logger,
  level: :info,
  # In production, consider using a more structured format like JSON
  format: "$time $metadata[$level] $message\n"

# Production HTTP timeouts
config :httpoison,
  timeout: 60_000,
  recv_timeout: 60_000
