# HospitableClient

Elixir client library for Hospitable Public API v2.

## Features

- Personal Access Token (PAT) authentication
- Centralized authentication state management with GenServer
- RESTful API support (GET, POST, PUT, PATCH, DELETE)
- Automatic JSON encoding/decoding
- Comprehensive error handling
- Environment-based configuration
- Periodic token validation

## Installation

Add `ex_hospitable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_hospitable, "~> 0.1.0"}
  ]
end
```

## Configuration

Create a `.env` file in your project root with your Hospitable API credentials:

```bash
# Hospitable API Configuration
HOSPITABLE_ACCESS_TOKEN=your_personal_access_token_here
HOSPITABLE_BASE_URL=https://public.api.hospitable.com/v2

# Optional: Timeout settings (in milliseconds)
HOSPITABLE_TIMEOUT=30000
HOSPITABLE_RECV_TIMEOUT=30000
```

## Usage

### Setting up Authentication

```elixir
# Set authentication token programmatically
HospitableClient.set_token("your_access_token")

# Check if authenticated
HospitableClient.authenticated?()
# => true
```

### Making API Requests

```elixir
# Get all properties
{:ok, properties} = HospitableClient.get("/properties")

# Get properties with included resources
{:ok, properties} = HospitableClient.get("/properties", %{"include" => "calendar"})

# Create a new property
{:ok, property} = HospitableClient.post("/properties", %{
  "name" => "My Vacation Rental",
  "address" => "123 Beach Street"
})

# Update a property
{:ok, property} = HospitableClient.put("/properties/123", %{
  "name" => "Updated Property Name"
})

# Partially update a property
{:ok, property} = HospitableClient.patch("/properties/123", %{
  "name" => "Partially Updated"
})

# Delete a property
{:ok, _} = HospitableClient.delete("/properties/123")
```

### Error Handling

The client returns structured error tuples for different types of failures:

```elixir
case HospitableClient.get("/properties") do
  {:ok, data} ->
    # Success
    process_properties(data)

  {:error, {:unauthorized, error_data}} ->
    # Authentication failed
    handle_auth_error(error_data)

  {:error, {:not_found, error_data}} ->
    # Resource not found
    handle_not_found(error_data)

  {:error, {:client_error, status, error_data}} ->
    # 4xx client error
    handle_client_error(status, error_data)

  {:error, {:server_error, status, error_data}} ->
    # 5xx server error
    handle_server_error(status, error_data)

  {:error, reason} ->
    # Other errors (network, JSON parsing, etc.)
    handle_error(reason)
end
```

### Authentication Management

The authentication state is managed by a GenServer that provides:

- Centralized token storage
- Periodic token validation
- Automatic authentication status tracking
- Token lifecycle management

```elixir
# Get current token
{:ok, token} = HospitableClient.get_token()

# Validate token manually
:ok = HospitableClient.Auth.Manager.validate_token()

# Clear authentication
:ok = HospitableClient.Auth.Manager.clear_auth()
```

## API Reference

### Main Module: `HospitableClient`

- `set_token/1` - Set authentication token
- `get_token/0` - Get current token
- `authenticated?/0` - Check authentication status
- `get/2` - Make GET request
- `post/2` - Make POST request
- `put/2` - Make PUT request
- `patch/2` - Make PATCH request
- `delete/1` - Make DELETE request

### Authentication: `HospitableClient.Auth.Manager`

- `set_token/1` - Set authentication token
- `get_token/0` - Get current token
- `get_credentials/0` - Get current credentials
- `authenticated?/0` - Check authentication status
- `validate_token/0` - Validate token with API
- `clear_auth/0` - Clear authentication state

## Development

### Running Tests

```bash
mix test
```

### Code Quality

```bash
# Run Credo for code analysis
mix credo

# Run Dialyzer for type checking
mix dialyzer
```

### Documentation

```bash
# Generate documentation
mix docs
```

## Architecture

The library is built with the following architectural principles:

1. **Centralized Authentication**: A GenServer manages all authentication state
2. **Separation of Concerns**: HTTP client and authentication are separate modules
3. **Fault Tolerance**: Supervisor tree ensures processes restart on failure
4. **Configuration Flexibility**: Environment-based configuration with sensible defaults
5. **Error Transparency**: Structured error returns for different failure modes

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Run the test suite and code quality checks
6. Submit a pull request

## License

MIT License - see LICENSE file for details.
