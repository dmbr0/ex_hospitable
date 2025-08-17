import Config

# General application configuration
config :ex_hospitable,
  # Environment-specific configuration will be loaded from .env files
  load_dotenv: true

# Configure logger
config :logger,
  level: :info,
  format: "$time $metadata[$level] $message\n"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
