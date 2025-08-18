defmodule HospitableClient.Properties do
  @moduledoc """
  Module for managing properties through the Hospitable API.

  This module provides functions for retrieving and managing properties,
  including support for pagination, filtering, and including related resources.

  ## Available Include Options

  When fetching properties, you can include related resources using the `include` parameter:
  - `"user"` - Include property owner information
  - `"listings"` - Include platform listings (requires listing:read scope)
  - `"details"` - Include detailed property information
  - `"bookings"` - Include booking policies and rules

  Multiple includes can be combined: `"user,listings,details,bookings"`

  ## Usage

      # Get all properties (first page, 10 per page)
      {:ok, response} = HospitableClient.Properties.get_properties()

      # Get properties with pagination and includes
      {:ok, response} = HospitableClient.Properties.get_properties(%{
        page: 2,
        per_page: 25,
        include: "user,listings,details"
      })

      # Get single property by UUID
      {:ok, property} = HospitableClient.Properties.get_property("550e8400-e29b-41d4-a716-446655440000")

      # Get single property with all includes
      {:ok, property} = HospitableClient.Properties.get_property(
        "550e8400-e29b-41d4-a716-446655440000",
        %{include: "user,listings,details,bookings"}
      )

  """

  alias HospitableClient.HTTP.Client

  # Valid include options as per API specification
  @valid_includes ~w(user listings details bookings)

  @doc """
  Retrieves a paginated list of properties.

  ## Parameters

  - `opts` - A map of options for the request

  ## Options

  - `:include` - Related resources to include. Valid values: #{inspect(@valid_includes)}
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
              "postcode" => "10405",
              "coordinates" => %{
                "latitude" => 52.5200,
                "longitude" => 13.4050
              },
              "display" => "32 Senefelderplatz, 10405 Berlin, DE"
            },
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

      # Get properties with includes
      iex> HospitableClient.Properties.get_properties(%{include: "user,listings"})
      {:ok, %{"data" => [...], "included" => [...]}}

  """
  @spec get_properties(map()) :: {:ok, map()} | {:error, term()}
  def get_properties(opts \\ %{}) do
    with {:ok, validated_opts} <- validate_options(opts),
         params <- build_query_params(validated_opts) do
      Client.get("/properties", params)
    end
  end

  @doc """
  Retrieves a single property by UUID.

  ## Parameters

  - `property_uuid` - The UUID of the property to retrieve (must be valid UUID format)
  - `opts` - A map of options for the request (optional)

  ## Options

  - `:include` - Related resources to include. Valid values: #{inspect(@valid_includes)}

  ## Examples

      # Get single property
      iex> HospitableClient.Properties.get_property("550e8400-e29b-41d4-a716-446655440000")
      {:ok, %{
        "id" => "550e8400-e29b-41d4-a716-446655440000",
        "name" => "Relaxing Villa near the sea",
        "address" => %{
          "coordinates" => %{
            "latitude" => 52.5200,
            "longitude" => 13.4050
          }
        },
        # ... complete property object
      }}

      # Get property with all includes
      iex> HospitableClient.Properties.get_property(
        "550e8400-e29b-41d4-a716-446655440000",
        %{include: "user,listings,details,bookings"}
      )
      {:ok, %{...}}

  ## Response Structure

  Returns a single property object with all the fields from the schema.
  Unlike the list endpoint, this returns the property directly (not wrapped in a data array).

  ## Errors

  - `{:error, :invalid_uuid}` - If the provided UUID is not in valid format
  - `{:error, {:not_found, error_data}}` - If property with given UUID doesn't exist
  - `{:error, {:unauthorized, error_data}}` - If authentication fails
  - `{:error, {:forbidden, error_data}}` - If access is denied

  """
  @spec get_property(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def get_property(property_uuid, opts \\ %{}) when is_binary(property_uuid) do
    with {:ok, _} <- validate_uuid(property_uuid),
         {:ok, validated_opts} <- validate_options(opts),
         params <- build_query_params(validated_opts) do
      Client.get("/properties/#{property_uuid}", params)
    end
  end

  @doc """
  Gets all properties across all pages.

  This function automatically handles pagination and returns all properties
  in a single response. Use with caution for accounts with many properties.

  ## Parameters

  - `opts` - A map of options for the request

  ## Options

  - `:include` - Related resources to include. Valid values: #{inspect(@valid_includes)}
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
    with {:ok, validated_opts} <- validate_options(opts) do
      per_page = Map.get(validated_opts, :per_page, 100)
      max_pages = Map.get(validated_opts, :max_pages, 50)

      # Ensure per_page doesn't exceed API limit
      per_page = min(per_page, 100)

      initial_opts = validated_opts
      |> Map.put(:page, 1)
      |> Map.put(:per_page, per_page)

      case get_properties(initial_opts) do
        {:ok, first_response} ->
          fetch_remaining_pages(first_response, validated_opts, per_page, max_pages, 1)

        {:error, reason} ->
          {:error, reason}
      end
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
  Calculates the distance between two properties based on their coordinates.

  ## Parameters

  - `property1` - First property with coordinates
  - `property2` - Second property with coordinates
  - `unit` - Unit for distance calculation (default: `:km`, options: `:km`, `:miles`)

  ## Examples

      iex> prop1 = %{"address" => %{"coordinates" => %{"latitude" => 52.5200, "longitude" => 13.4050}}}
      iex> prop2 = %{"address" => %{"coordinates" => %{"latitude" => 48.1351, "longitude" => 11.5820}}}
      iex> HospitableClient.Properties.distance_between(prop1, prop2)
      {:ok, 504.2}

      iex> HospitableClient.Properties.distance_between(prop1, prop2, :miles)
      {:ok, 313.4}

  """
  @spec distance_between(map(), map(), atom()) :: {:ok, float()} | {:error, term()}
  def distance_between(property1, property2, unit \\ :km) do
    with {:ok, {lat1, lon1}} <- extract_coordinates(property1),
         {:ok, {lat2, lon2}} <- extract_coordinates(property2) do
      distance = haversine_distance(lat1, lon1, lat2, lon2, unit)
      {:ok, distance}
    end
  end

  @doc """
  Finds properties within a specified radius of given coordinates.

  ## Parameters

  - `properties` - List of properties or response map
  - `center_lat` - Center latitude
  - `center_lon` - Center longitude
  - `radius` - Search radius
  - `unit` - Unit for radius (default: `:km`, options: `:km`, `:miles`)

  ## Examples

      iex> # Find properties within 10km of Berlin city center
      iex> nearby = HospitableClient.Properties.find_nearby(response, 52.5200, 13.4050, 10)
      [%{"id" => "...", "address" => %{...}}, ...]

  """
@spec find_nearby(map() | list(), float(), float(), float(), atom()) :: list(map())
def find_nearby(properties, center_lat, center_lon, radius, unit \\ :km)

def find_nearby(%{"data" => properties}, center_lat, center_lon, radius, unit) when is_list(properties) do
  find_nearby(properties, center_lat, center_lon, radius, unit)
end

def find_nearby(properties, center_lat, center_lon, radius, unit) when is_list(properties) do
    properties
    |> Enum.filter(fn property ->
      case extract_coordinates(property) do
        {:ok, {lat, lon}} ->
          distance = haversine_distance(center_lat, center_lon, lat, lon, unit)
          distance <= radius
        {:error, _} ->
          false
      end
    end)
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
  - `:within_radius` - Filter by distance from coordinates `%{lat: float, lon: float, radius: float, unit: :km/:miles}`

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

      # Location-based filtering with coordinates
      iex> nearby_berlin = HospitableClient.Properties.filter_properties(response, %{
        within_radius: %{lat: 52.5200, lon: 13.4050, radius: 10, unit: :km}
      })

      # Advanced filtering
      iex> luxury_properties = HospitableClient.Properties.filter_properties(response, %{
        currency: "USD",
        has_amenities: ["pool", "gym", "concierge"],
        events_allowed: true,
        min_capacity: 8
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

  @doc """
  Validates if a string is a valid UUID format.

  ## Examples

      iex> HospitableClient.Properties.valid_uuid?("550e8400-e29b-41d4-a716-446655440000")
      true

      iex> HospitableClient.Properties.valid_uuid?("invalid-uuid")
      false

  """
  @spec valid_uuid?(String.t()) :: boolean()
  def valid_uuid?(uuid) when is_binary(uuid) do
    case validate_uuid(uuid) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  # Private Functions

  defp validate_options(opts) when is_map(opts) do
    case validate_include_option(opts) do
      {:ok, validated_opts} -> {:ok, validated_opts}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_include_option(opts) do
    case Map.get(opts, :include) do
      nil ->
        {:ok, opts}
      include_string when is_binary(include_string) ->
        includes = String.split(include_string, ",", trim: true)
        invalid_includes = includes -- @valid_includes

        if Enum.empty?(invalid_includes) do
          {:ok, opts}
        else
          {:error, {:invalid_includes, invalid_includes, @valid_includes}}
        end
      _ ->
        {:error, {:invalid_include_format, "Include must be a string"}}
    end
  end

  defp validate_uuid(uuid) when is_binary(uuid) do
    # UUID v4 regex pattern
    uuid_pattern = ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

    if Regex.match?(uuid_pattern, uuid) do
      {:ok, uuid}
    else
      {:error, :invalid_uuid}
    end
  end

  defp extract_coordinates(property) do
    case get_in(property, ["address", "coordinates"]) do
      %{"latitude" => lat, "longitude" => lon} when is_number(lat) and is_number(lon) ->
        {:ok, {lat, lon}}
      _ ->
        {:error, :no_coordinates}
    end
  end

  defp haversine_distance(lat1, lon1, lat2, lon2, unit) do
    # Convert degrees to radians
    lat1_rad = :math.pi() * lat1 / 180
    lon1_rad = :math.pi() * lon1 / 180
    lat2_rad = :math.pi() * lat2 / 180
    lon2_rad = :math.pi() * lon2 / 180

    # Haversine formula
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad

    a = :math.pow(:math.sin(dlat / 2), 2) +
        :math.cos(lat1_rad) * :math.cos(lat2_rad) * :math.pow(:math.sin(dlon / 2), 2)
    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))

    # Earth's radius
    radius = case unit do
      :km -> 6371.0
      :miles -> 3959.0
    end

    # Calculate distance
    distance = radius * c
    Float.round(distance, 1)
  end

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

  defp passes_filter?(property, :within_radius, %{lat: lat, lon: lon, radius: radius} = opts) do
    unit = Map.get(opts, :unit, :km)
    case extract_coordinates(property) do
      {:ok, {prop_lat, prop_lon}} ->
        distance = haversine_distance(lat, lon, prop_lat, prop_lon, unit)
        distance <= radius
      {:error, _} ->
        false
    end
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
