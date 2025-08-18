defmodule HospitableClient.Properties do
  @moduledoc """
  Module for managing properties through the Hospitable API.

  This module provides functions for retrieving and managing properties,
  including support for pagination, filtering, and including related resources.

  ## Usage

      # Get all properties (first page, 10 per page)
      {:ok, response} = HospitableClient.Properties.get_properties()

      # Get properties with pagination
      {:ok, response} = HospitableClient.Properties.get_properties(%{
        page: 2,
        per_page: 25
      })

      # Get properties with included resources
      {:ok, response} = HospitableClient.Properties.get_properties(%{
        include: "listings,user,details,bookings"
      })

  """

  alias HospitableClient.HTTP.Client

  @doc """
  Retrieves a paginated list of properties.

  ## Parameters

  - `opts` - A map of options for the request

  ## Options

  - `:include` - Related resources to include. Allowed values: "listings", "user", "details", "bookings"
  - `:page` - Page of results (default: 1)
  - `:per_page` - Results per page, max 100 (default: 10)

  ## Examples

      # Get first page of properties
      iex> HospitableClient.Properties.get_properties()
      {:ok, %{
        "data" => [
          %{
            "id" => "550e8400-e29b-41d4-a716-446655440000",
            "name" => "Relaxing Villa near the sea",
            "public_name" => "Relaxing Villa near the sea",
            "picture" => "https://example.com/image.jpg",
            "address" => %{
              "number" => "32",
              "street" => "Senefelderplatz", 
              "city" => "Berlin",
              "state" => "Berlin",
              "country" => "DE",
              "postcode" => "10405"
            },
            "coordinates" => %{"display" => "52.5200,13.4050"},
            "timezone" => "+0200",
            "listed" => true,
            "amenities" => ["wifi", "kitchen", "parking"],
            "description" => "Beautiful property...",
            "summary" => "Perfect for vacation...",
            "check-in" => "15:00",
            "check-out" => "11:00", 
            "currency" => "EUR",
            "capacity" => %{"max" => 4, "bedrooms" => 2, "beds" => 2, "bathrooms" => 1},
            # ... more fields
          }
        ],
        "links" => %{...},
        "meta" => %{...}
      }}

  ## Property Object Structure

  Each property contains comprehensive information:
  - `id` - Property UUID
  - `name` - Internal property name
  - `public_name` - Public display name
  - `picture` - Property image URL
  - `address` - Complete address with number, street, city, state, country, postcode
  - `coordinates` - Location coordinates
  - `timezone` - Property timezone
  - `listed` - Whether property is currently listed
  - `amenities` - Array of amenity strings
  - `description` - Full property description
  - `summary` - Short property summary
  - `check-in`/`check-out` - Times in HH:MM format
  - `currency` - 3-letter currency code
  - `capacity` - Guest capacity details (max, bedrooms, beds, bathrooms)
  - `room_details` - Array of room types and quantities
  - `house_rules` - Rules for pets, smoking, events
  - `listings` - Platform listings with detailed info
  - `host` - Host information
  - `tags` - Property tags
  - `property_type` - Type of property
  - `room_type` - Type of accommodation
  - `calendar_restricted` - Calendar restriction status
  - `bookings` - Booking policies, fees, discounts
  - `details` - Additional property details
  - `user` - Owner user information

  """
  @spec get_properties(map()) :: {:ok, map()} | {:error, term()}
  def get_properties(opts \\ %{}) do
    params = build_query_params(opts)
    Client.get("/properties", params)
  end

  @doc """
  Retrieves a single property by ID.

  ## Parameters

  - `property_id` - The UUID of the property to retrieve
  - `opts` - A map of options for the request (optional)

  ## Options

  - `:include` - Related resources to include. Allowed values: "listings", "user", "details", "bookings"

  ## Examples

      iex> HospitableClient.Properties.get_property("550e8400-e29b-41d4-a716-446655440000")
      {:ok, %{
        "data" => %{
          "id" => "550e8400-e29b-41d4-a716-446655440000",
          "name" => "Relaxing Villa near the sea",
          # ... complete property object
        }
      }}

      # Get property with all includes
      iex> HospitableClient.Properties.get_property("550e8400-e29b-41d4-a716-446655440000", %{
        include: "listings,user,details,bookings"
      })
      {:ok, %{"data" => %{...}, "included" => [...]}}

  """
  @spec get_property(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def get_property(property_id, opts \\ %{}) when is_binary(property_id) do
    params = build_query_params(opts)
    Client.get("/properties/#{property_id}", params)
  end

  @doc """
  Gets all properties across all pages.

  This function automatically handles pagination and returns all properties
  in a single response. Use with caution for accounts with many properties.

  ## Parameters

  - `opts` - A map of options for the request

  ## Options

  - `:include` - Related resources to include
  - `:per_page` - Results per page for internal pagination (default: 100, max: 100)
  - `:max_pages` - Maximum number of pages to fetch (default: 50, safety limit)

  ## Examples

      iex> HospitableClient.Properties.get_all_properties()
      {:ok, %{
        "data" => [...],  # All properties across all pages
        "meta" => %{
          "total_pages" => 5,
          "total_properties" => 234,
          "fetched_pages" => 5
        }
      }}

      # With included resources
      iex> HospitableClient.Properties.get_all_properties(%{include: "listings,bookings"})
      {:ok, %{"data" => [...], "included" => [...], "meta" => %{...}}}

  """
  @spec get_all_properties(map()) :: {:ok, map()} | {:error, term()}
  def get_all_properties(opts \\ %{}) do
    per_page = Map.get(opts, :per_page, 100)
    max_pages = Map.get(opts, :max_pages, 50)
    
    # Ensure per_page doesn't exceed API limit
    per_page = min(per_page, 100)
    
    initial_opts = opts
    |> Map.put(:page, 1)
    |> Map.put(:per_page, per_page)
    
    case get_properties(initial_opts) do
      {:ok, first_response} ->
        fetch_remaining_pages(first_response, opts, per_page, max_pages, 1)
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Lists all available property amenities.

  This is a convenience function that extracts all unique amenities
  from a set of properties.

  ## Parameters

  - `properties` - List of property maps or a response map with data key

  ## Examples

      iex> {:ok, response} = HospitableClient.Properties.get_properties()
      iex> amenities = HospitableClient.Properties.list_amenities(response)
      ["wifi", "kitchen", "parking", "pool", ...]

      # Or pass properties directly
      iex> amenities = HospitableClient.Properties.list_amenities(response["data"])
      ["wifi", "kitchen", "parking", "pool", ...]

  """
  @spec list_amenities(map() | list()) :: list(String.t())
  def list_amenities(%{"data" => properties}) when is_list(properties) do
    list_amenities(properties)
  end
  
  def list_amenities(properties) when is_list(properties) do
    properties
    |> Enum.flat_map(fn property -> 
      Map.get(property, "amenities", [])
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Lists all available property types from a set of properties.

  ## Examples

      iex> {:ok, response} = HospitableClient.Properties.get_properties()
      iex> types = HospitableClient.Properties.list_property_types(response)
      ["apartment", "house", "villa", ...]

  """
  @spec list_property_types(map() | list()) :: list(String.t())
  def list_property_types(%{"data" => properties}) when is_list(properties) do
    list_property_types(properties)
  end

  def list_property_types(properties) when is_list(properties) do
    properties
    |> Enum.map(fn property -> Map.get(property, "property_type") end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Lists all currencies used across properties.

  ## Examples

      iex> currencies = HospitableClient.Properties.list_currencies(response)
      ["EUR", "USD", "GBP", ...]

  """
  @spec list_currencies(map() | list()) :: list(String.t())
  def list_currencies(%{"data" => properties}) when is_list(properties) do
    list_currencies(properties)
  end

  def list_currencies(properties) when is_list(properties) do
    properties
    |> Enum.map(fn property -> Map.get(property, "currency") end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Filters properties by specific criteria.

  This is a client-side filtering function that works on already-fetched properties.
  For server-side filtering, use the API's query parameters.

  ## Parameters

  - `properties` - List of property maps or a response map with data key
  - `filters` - Map of filter criteria

  ## Filter Options

  **Basic Filters:**
  - `:listed` - Filter by listed status (true/false)
  - `:property_type` - Filter by property type
  - `:room_type` - Filter by room type
  - `:currency` - Filter by currency code

  **Location Filters:**
  - `:city` - Filter by city name (case insensitive)
  - `:state` - Filter by state name (case insensitive)
  - `:country` - Filter by country code (case insensitive)

  **Capacity Filters:**
  - `:min_capacity` - Minimum guest capacity
  - `:max_capacity` - Maximum guest capacity
  - `:min_bedrooms` - Minimum number of bedrooms
  - `:min_bathrooms` - Minimum number of bathrooms

  **Feature Filters:**
  - `:has_amenities` - Filter properties that have ALL specified amenities
  - `:calendar_restricted` - Filter by calendar restriction status

  **Rule Filters:**
  - `:pets_allowed` - Filter by pet policy
  - `:smoking_allowed` - Filter by smoking policy
  - `:events_allowed` - Filter by events policy

  ## Examples

      iex> {:ok, response} = HospitableClient.Properties.get_properties()
      
      # Basic filtering
      iex> listed_properties = HospitableClient.Properties.filter_properties(response, %{listed: true})
      
      # Location filtering
      iex> berlin_properties = HospitableClient.Properties.filter_properties(response, %{city: "Berlin"})
      
      # Capacity filtering
      iex> large_properties = HospitableClient.Properties.filter_properties(response, %{min_capacity: 6})
      
      # Amenity filtering
      iex> properties_with_pool = HospitableClient.Properties.filter_properties(response, %{
        has_amenities: ["pool", "wifi"]
      })
      
      # House rules filtering
      iex> pet_friendly = HospitableClient.Properties.filter_properties(response, %{pets_allowed: true})
      
      # Combined filtering
      iex> filtered = HospitableClient.Properties.filter_properties(response, %{
        listed: true,
        city: "Berlin",
        min_capacity: 4,
        has_amenities: ["wifi", "kitchen"],
        pets_allowed: true,
        currency: "EUR"
      })

  """
  @spec filter_properties(map() | list(), map()) :: list(map())
  def filter_properties(%{"data" => properties}, filters) when is_list(properties) do
    filter_properties(properties, filters)
  end
  
  def filter_properties(properties, filters) when is_list(properties) and is_map(filters) do
    Enum.filter(properties, fn property ->
      passes_all_filters?(property, filters)
    end)
  end

  @doc """
  Groups properties by a specific field.

  ## Examples

      iex> grouped = HospitableClient.Properties.group_properties(response, :city)
      %{
        "Berlin" => [property1, property2],
        "Munich" => [property3]
      }

      iex> by_type = HospitableClient.Properties.group_properties(response, :property_type)
      %{
        "apartment" => [...],
        "house" => [...],
        "villa" => [...]
      }

  """
  @spec group_properties(map() | list(), atom()) :: map()
  def group_properties(%{"data" => properties}, group_by) when is_list(properties) do
    group_properties(properties, group_by)
  end

  def group_properties(properties, group_by) when is_list(properties) and is_atom(group_by) do
    field_name = Atom.to_string(group_by)
    
    case group_by do
      :city -> group_by_nested_field(properties, ["address", "city"])
      :state -> group_by_nested_field(properties, ["address", "state"])
      :country -> group_by_nested_field(properties, ["address", "country"])
      _ -> group_by_field(properties, field_name)
    end
  end

  # Private Functions

  defp build_query_params(opts) do
    opts
    |> Map.take([:include, :page, :per_page])
    |> Enum.into(%{}, fn {key, value} -> {Atom.to_string(key), value} end)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end

  defp fetch_remaining_pages(first_response, opts, per_page, max_pages, current_page) do
    all_data = first_response["data"] || []
    all_included = first_response["included"] || []
    
    meta = first_response["meta"] || %{}
    total = Map.get(meta, "total", 0)
    total_pages = ceil(total / per_page)
    
    if current_page >= total_pages or current_page >= max_pages do
      # We have all pages or hit the safety limit
      {:ok, %{
        "data" => all_data,
        "included" => all_included,
        "meta" => %{
          "total_pages" => total_pages,
          "total_properties" => total,
          "fetched_pages" => current_page
        }
      }}
    else
      # Fetch next page
      next_page = current_page + 1
      next_opts = opts
      |> Map.put(:page, next_page)
      |> Map.put(:per_page, per_page)
      
      case get_properties(next_opts) do
        {:ok, next_response} ->
          # Combine data from both responses
          combined_response = %{
            "data" => all_data ++ (next_response["data"] || []),
            "included" => all_included ++ (next_response["included"] || []),
            "meta" => next_response["meta"] || %{}
          }
          
          fetch_remaining_pages(combined_response, opts, per_page, max_pages, next_page)
          
        {:error, reason} ->
          # Return what we have so far
          {:ok, %{
            "data" => all_data,
            "included" => all_included,
            "meta" => %{
              "total_pages" => total_pages,
              "total_properties" => total,
              "fetched_pages" => current_page,
              "error" => "Failed to fetch page #{next_page}: #{inspect(reason)}"
            }
          }}
      end
    end
  end

  defp passes_all_filters?(property, filters) do
    Enum.all?(filters, fn {filter_key, filter_value} ->
      passes_filter?(property, filter_key, filter_value)
    end)
  end

  # Basic property filters
  defp passes_filter?(property, :listed, expected_value) do
    Map.get(property, "listed") == expected_value
  end

  defp passes_filter?(property, :property_type, expected_type) do
    Map.get(property, "property_type") == expected_type
  end

  defp passes_filter?(property, :room_type, expected_type) do
    Map.get(property, "room_type") == expected_type
  end

  defp passes_filter?(property, :currency, expected_currency) do
    Map.get(property, "currency") == expected_currency
  end

  defp passes_filter?(property, :calendar_restricted, expected_value) do
    Map.get(property, "calendar_restricted") == expected_value
  end

  # Location filters
  defp passes_filter?(property, :city, expected_city) do
    city = get_in(property, ["address", "city"])
    city && String.downcase(city) == String.downcase(expected_city)
  end

  defp passes_filter?(property, :state, expected_state) do
    state = get_in(property, ["address", "state"])
    state && String.downcase(state) == String.downcase(expected_state)
  end

  defp passes_filter?(property, :country, expected_country) do
    country = get_in(property, ["address", "country"])
    country && String.downcase(country) == String.downcase(expected_country)
  end

  # Capacity filters
  defp passes_filter?(property, :min_capacity, min_capacity) do
    capacity = get_in(property, ["capacity", "max"]) || 0
    capacity >= min_capacity
  end

  defp passes_filter?(property, :max_capacity, max_capacity) do
    capacity = get_in(property, ["capacity", "max"]) || 0
    capacity <= max_capacity
  end

  defp passes_filter?(property, :min_bedrooms, min_bedrooms) do
    bedrooms = get_in(property, ["capacity", "bedrooms"]) || 0
    bedrooms >= min_bedrooms
  end

  defp passes_filter?(property, :min_bathrooms, min_bathrooms) do
    bathrooms = get_in(property, ["capacity", "bathrooms"]) || 0
    bathrooms >= min_bathrooms
  end

  # Amenity filters
  defp passes_filter?(property, :has_amenities, required_amenities) when is_list(required_amenities) do
    property_amenities = Map.get(property, "amenities", [])
    Enum.all?(required_amenities, fn amenity ->
      Enum.member?(property_amenities, amenity)
    end)
  end

  # House rules filters
  defp passes_filter?(property, :pets_allowed, expected_value) do
    get_in(property, ["house_rules", "pets_allowed"]) == expected_value
  end

  defp passes_filter?(property, :smoking_allowed, expected_value) do
    get_in(property, ["house_rules", "smoking_allowed"]) == expected_value
  end

  defp passes_filter?(property, :events_allowed, expected_value) do
    get_in(property, ["house_rules", "events_allowed"]) == expected_value
  end

  defp passes_filter?(_property, _filter_key, _filter_value) do
    # Unknown filter, don't filter out the property
    true
  end

  defp group_by_field(properties, field_name) do
    Enum.group_by(properties, fn property ->
      Map.get(property, field_name, "Unknown")
    end)
  end

  defp group_by_nested_field(properties, field_path) do
    Enum.group_by(properties, fn property ->
      get_in(property, field_path) || "Unknown"
    end)
  end
end
