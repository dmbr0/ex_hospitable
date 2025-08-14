import Config

# Load .env file in development and test environments
if Mix.env() in [:dev, :test] do
  try do
    DotenvParser.load_file(".env")
  rescue
    _ -> :ok
  end
end

config :ex_hospitable,
  api_key: System.get_env("HOSPITABLE_API_KEY"),
  base_url: System.get_env("HOSPITABLE_BASE_URL") || "https://api.hospitable.com"