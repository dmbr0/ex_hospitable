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
# Get all properties (first page, 10 per page)
{:ok, properties} = HospitableClient.get_properties()

# Get properties with pagination
{:ok, properties} = HospitableClient.get_properties(%{
  page: 2,
  per_page: 25
})

# Get properties with included resources (API specification compliant)
{:ok, properties} = HospitableClient.get_properties(%{
  include: "user,listings,details,bookings"
})

# Get single property by UUID
{:ok, property} = HospitableClient.get_property("550e8400-e29b-41d4-a716-446655440000")

# Get single property with all includes
{:ok, property} = HospitableClient.get_property(
  "550e8400-e29b-41d4-a716-446655440000",
  %{include: "user,listings,details,bookings"}
)

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

### Properties Module - Advanced Features

The `HospitableClient.Properties` module provides specialized functions for property management:

```elixir
# Get all properties across all pages (handles pagination automatically)
{:ok, all_properties} = HospitableClient.Properties.get_all_properties()

# Get properties with custom pagination settings
{:ok, properties} = HospitableClient.Properties.get_all_properties(%{
  per_page: 100,        # Max page size for faster fetching
  max_pages: 10,        # Safety limit
  include: "listings"   # Include related resources
})

# Extract all unique amenities from properties
{:ok, response} = HospitableClient.get_properties()
amenities = HospitableClient.Properties.list_amenities(response)
# => ["wifi", "kitchen", "parking", "pool", ...]

# Extract property types and currencies
property_types = HospitableClient.Properties.list_property_types(response)
currencies = HospitableClient.Properties.list_currencies(response)

# Calculate distance between properties (using coordinates)
prop1 = response["data"] |> List.first()
prop2 = response["data"] |> List.last()
{:ok, distance_km} = HospitableClient.Properties.distance_between(prop1, prop2, :km)
{:ok, distance_miles} = HospitableClient.Properties.distance_between(prop1, prop2, :miles)

# Find properties near specific coordinates (10km radius around Berlin)
nearby_berlin = HospitableClient.Properties.find_nearby(response, 52.5200, 13.4050, 10, :km)

# Filter properties (client-side)
berlin_properties = HospitableClient.Properties.filter_properties(response, %{
  city: "Berlin"
})

listed_with_kitchen = HospitableClient.Properties.filter_properties(response, %{
  listed: true,
  has_amenities: ["kitchen"]
})

large_properties = HospitableClient.Properties.filter_properties(response, %{
  min_capacity: 4
})

# Advanced filtering with new options
pet_friendly_villas = HospitableClient.Properties.filter_properties(response, %{
  property_type: "villa",
  pets_allowed: true,
  min_bedrooms: 3
})

# Location-based filtering with coordinates
nearby_properties = HospitableClient.Properties.filter_properties(response, %{
  within_radius: %{lat: 52.5200, lon: 13.4050, radius: 50, unit: :km}
})

# Ultra-luxury property search
luxury_properties = HospitableClient.Properties.filter_properties(response, %{
  currency: "USD",
  has_amenities: ["pool", "gym", "concierge"],
  events_allowed: true,
  min_capacity: 8,
  within_radius: %{lat: 40.7589, lon: -73.9851, radius: 25, unit: :miles}
})
```

#### Available Filter Options

**Basic Filters:**
- `:listed` - Filter by listed status (true/false)
- `:property_type` - Filter by property type (villa, apartment, penthouse, etc.)
- `:room_type` - Filter by room type (entire_place, private_room, etc.)
- `:currency` - Filter by currency code (EUR, USD, GBP, etc.)
- `:calendar_restricted` - Filter by calendar restriction status

**Location Filters:**
- `:city` - Filter by city name (case insensitive)
- `:state` - Filter by state/region name (case insensitive)
- `:country` - Filter by country code (case insensitive)
- `:within_radius` - Filter by distance from coordinates `%{lat: float, lon: float, radius: float, unit: :km/:miles}`

**Capacity Filters:**
- `:min_capacity` - Filter by minimum guest capacity
- `:max_capacity` - Filter by maximum guest capacity
- `:min_bedrooms` - Filter by minimum number of bedrooms
- `:min_bathrooms` - Filter by minimum number of bathrooms

**Feature Filters:**
- `:has_amenities` - Filter properties that have ALL specified amenities

**House Rules Filters:**
- `:pets_allowed` - Filter by pet policy (true/false)
- `:smoking_allowed` - Filter by smoking policy (true/false)
- `:events_allowed` - Filter by events policy (true/false)

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
- `get_properties/1` - Get paginated list of properties
- `get_property/2` - Get single property by ID

### Properties Module: `HospitableClient.Properties`

- `get_properties/1` - Get paginated list of properties with full options
- `get_property/2` - Get single property by UUID with options
- `get_all_properties/1` - Get all properties across all pages
- `list_amenities/1` - Extract unique amenities from properties
- `list_property_types/1` - Extract unique property types from properties
- `list_currencies/1` - Extract unique currencies from properties
- `filter_properties/2` - Filter properties by various criteria
- `group_properties/2` - Group properties by a specific field
- `distance_between/3` - Calculate distance between two properties
- `find_nearby/5` - Find properties within radius of coordinates
- `valid_uuid?/1` - Validate UUID format

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
