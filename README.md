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

### Automatic Configuration (Recommended)

The easiest way to use HospitableClient is with automatic configuration. Set your API key in a `.env` file or environment variable:

```bash
# .env file
HOSPITABLE_API_KEY=your-hospitable-api-key

# Or export as environment variable
export HOSPITABLE_API_KEY="your-hospitable-api-key"
```

Then use the API functions directly without passing configuration:

```elixir
# API functions automatically use configured credentials
{:ok, properties} = HospitableClient.get_properties()
{:ok, reservations} = HospitableClient.get_reservations(include: "guest")
{:ok, messages} = HospitableClient.get_messages("reservation-uuid")
```

### Manual Configuration

For more control, you can still configure the client manually:

#### 1. Direct API Key

```elixir
# Create a client with your API key
client = HospitableClient.new("your-hospitable-api-key")

# Use with explicit configuration
{:ok, properties} = HospitableClient.get_properties(client)
```

#### 2. From Environment Configuration

```elixir
# Load from environment/config
{:ok, client} = HospitableClient.from_env()

# Use with explicit configuration
{:ok, reservations} = HospitableClient.get_reservations(client, include: "guest")
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
# With automatic configuration (recommended)
{:ok, reservations} = HospitableClient.get_reservations(
  properties: ["property-uuid"],
  include: "guest,financials"
)

{:ok, results} = HospitableClient.search_properties(
  adults: 2,
  start_date: "2024-08-16", 
  end_date: "2024-08-21"
)

{:ok, properties} = HospitableClient.get_properties(
  include: "details,bookings"
)

{:ok, messages} = HospitableClient.get_messages("reservation-uuid")

{:ok, response} = HospitableClient.send_message(
  "reservation-uuid",
  body: "Hello! Your check-in is at 3 PM."
)

# With manual configuration
client = HospitableClient.new("your-api-key")
{:ok, reservations} = HospitableClient.get_reservations(client, include: "guest")
```

For comprehensive usage examples and interactive shell demonstrations, see [EXAMPLES.md](EXAMPLES.md).

## Configuration Priority

The client checks for API keys in the following order:

1. **Manual configuration** passed to functions (highest priority)
2. **Application configuration**: `config :ex_hospitable, api_key: "..."`  
3. **Environment variable**: `HOSPITABLE_API_KEY`
4. **.env file**: Automatically loaded in development/test environments

## Features

- **Automatic configuration loading** - Set API key once via environment, use everywhere
- **Manual configuration override** - Still supports explicit client configuration
- **Comprehensive API coverage** - Reservations, Properties, and Messages endpoints
- **Type safety** - Full Elixir typespecs for all functions and return types
- **Error handling** - Structured error responses for all failure scenarios
- **Development friendly** - Automatic .env file loading in dev/test environments

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_hospitable>.

