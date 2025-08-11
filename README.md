# HospitableClient

An Elixir client library for the Hospitable API, providing authentication and configuration management for making requests to Hospitable services.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_hospitable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_hospitable, "~> 0.1.0"}
  ]
end
```

## Usage

### Authentication

The client supports multiple ways to configure your API key:

#### 1. Direct API Key

```elixir
# Create a client with your API key
client = HospitableClient.new("your-hospitable-api-key")
```

#### 2. From Environment Configuration

Set your API key via application configuration:

```elixir
# In your config/config.exs
config :ex_hospitable, api_key: "your-hospitable-api-key"

# Then create the client
{:ok, client} = HospitableClient.from_env()
```

Or via environment variable:

```bash
export HOSPITABLE_API_KEY="your-hospitable-api-key"
```

```elixir
{:ok, client} = HospitableClient.from_env()
```

### Generating Authentication Headers

Once you have a client configuration, you can generate the appropriate headers for API requests:

```elixir
# Generate headers with Bearer token
headers = HospitableClient.Auth.headers(client.api_key)
# => [{"Authorization", "Bearer your-hospitable-api-key"}, {"Content-Type", "application/json"}]
```

### Custom Base URL

You can override the default API base URL if needed:

```elixir
client = HospitableClient.Config.new("your-api-key", base_url: "https://custom.hospitable.com")
```

### API Key Validation

The client includes basic API key validation:

```elixir
HospitableClient.Auth.valid_api_key?("your-key")  # => true
HospitableClient.Auth.valid_api_key?("")          # => false
HospitableClient.Auth.valid_api_key?(nil)         # => false
```

## Available APIs

This client library provides comprehensive support for the Hospitable API endpoints:

### Reservations API
- `get_reservations/2` - Retrieve multiple reservations with filtering and pagination
- `get_reservation/3` - Get a specific reservation by UUID
- Status helpers for reservation management and analysis

### Properties API  
- `get_properties/2` - Retrieve all properties with pagination and includes
- `search_properties/2` - Search available properties by dates, guests, and location
- Property helpers for rules, capacity, and availability checking

### Messages API
- `get_messages/2` - Retrieve all messages for a specific reservation  
- `send_message/3` - Send messages to reservation conversations
- Support for text messages and image attachments

### Quick Start Examples

```elixir
# Get reservations
{:ok, reservations} = HospitableClient.get_reservations(client,
  properties: ["property-uuid"],
  include: "guest,financials"
)

# Search properties
{:ok, results} = HospitableClient.search_properties(client,
  adults: 2,
  start_date: "2024-08-16",
  end_date: "2024-08-21"
)

# Get all properties
{:ok, properties} = HospitableClient.get_properties(client,
  include: "details,bookings"
)

# Get reservation messages
{:ok, messages} = HospitableClient.get_messages(client,
  "reservation-uuid"
)

# Send a message
{:ok, response} = HospitableClient.send_message(client,
  "reservation-uuid",
  body: "Hello! Your check-in is at 3 PM."
)
```

For comprehensive usage examples and interactive shell demonstrations, see [EXAMPLES.md](EXAMPLES.md).

## Configuration Priority

The client checks for API keys in the following order:

1. Application configuration: `config :ex_hospitable, api_key: "..."`
2. Environment variable: `HOSPITABLE_API_KEY`

Application configuration takes precedence over environment variables.

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_hospitable>.

