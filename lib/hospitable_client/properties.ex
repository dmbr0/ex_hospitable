defmodule HospitableClient.Properties do
  @moduledoc """
  Properties API functionality for the Hospitable client.
  
  This module provides functions to interact with property endpoints,
  including fetching all properties and searching for available properties.
  """

  @base_url "https://public.api.hospitable.com/v2"

  @type config :: HospitableClient.Config.config()
  @type uuid :: String.t()
  @type date :: String.t()
  @type datetime :: String.t()

  @type address :: %{
          number: String.t(),
          street: String.t(),
          city: String.t(),
          state: String.t(),
          country: String.t(),
          postcode: String.t(),
          coordinates: %{
            latitude: float(),
            longitude: float()
          },
          display: String.t()
        }

  @type capacity :: %{
          max: integer(),
          bedrooms: integer(),
          beds: integer(),
          bathrooms: integer()
        }

  @type room_detail :: %{
          type: String.t(),
          quantity: integer()
        }

  @type house_rules :: %{
          pets_allowed: boolean(),
          smoking_allowed: boolean(),
          events_allowed: boolean() | nil
        }

  @type listing :: %{
          platform: String.t(),
          platform_id: String.t(),
          platform_name: String.t(),
          platform_email: String.t()
        }

  @type ical_import :: %{
          uuid: uuid(),
          url: String.t(),
          name: String.t(),
          host: %{
            first_name: String.t(),
            last_name: String.t()
          },
          last_sync_at: datetime(),
          disconnected_at: datetime()
        }

  @type parent_child :: %{
          type: String.t(),
          parent: uuid(),
          children: list(uuid()),
          siblings: list(uuid())
        }

  @type user :: %{
          id: uuid(),
          email: String.t(),
          name: String.t()
        }

  @type property_details :: %{
          space_overview: String.t(),
          guest_access: String.t(),
          house_manual: String.t(),
          other_details: String.t(),
          additional_rules: String.t(),
          neighborhood_description: String.t(),
          getting_around: String.t(),
          wifi_name: String.t(),
          wifi_password: String.t()
        }

  @type monetary_value :: %{
          amount: integer(),
          formatted: String.t()
        }

  @type fee_value :: %{
          type: String.t(),
          value: monetary_value()
        }

  @type booking_policies :: %{
          cancellation: list(String.t()),
          payment_terms: %{
            status: String.t(),
            description: list(String.t()),
            grace_period: String.t()
          }
        }

  @type listing_markup :: %{
          platform: String.t(),
          type: String.t(),
          value: float()
        }

  @type security_deposit :: %{
          name: String.t(),
          type: String.t(),
          value: monetary_value()
        }

  @type occupancy_rules :: %{
          guests_included: integer(),
          extra_guest_fee: fee_value(),
          pet_fee: fee_value()
        }

  @type fee :: %{
          name: String.t(),
          type: String.t(),
          value: any()
        }

  @type discount :: %{
          name: String.t(),
          type: String.t(),
          value: float()
        }

  @type bookings :: %{
          booking_policies: booking_policies(),
          listing_markups: list(listing_markup()),
          security_deposits: list(security_deposit()),
          occupancy_based_rules: occupancy_rules(),
          fees: list(fee()),
          discounts: list(discount())
        }

  @type property :: %{
          id: uuid(),
          name: String.t(),
          public_name: String.t(),
          picture: String.t(),
          address: address(),
          timezone: String.t(),
          listed: boolean(),
          amenities: list(String.t()),
          description: String.t(),
          summary: String.t(),
          check_in: String.t(),
          check_out: String.t(),
          currency: String.t(),
          capacity: capacity(),
          room_details: list(room_detail()),
          house_rules: house_rules(),
          listings: list(listing()) | nil,
          ical_imports: list(ical_import()),
          tags: list(String.t()),
          property_type: String.t(),
          room_type: String.t(),
          calendar_restricted: boolean(),
          parent_child: parent_child() | nil,
          user: user() | nil,
          details: property_details() | nil,
          bookings: bookings() | nil
        }

  @type price_info :: %{
          currency: String.t(),
          amount: integer(),
          formatted_string: String.t(),
          formatted_decimal: String.t()
        }

  @type daily_price :: %{
          date: date(),
          price: price_info()
        }

  @type pricing :: %{
          daily: list(daily_price()),
          total_without_taxes: price_info(),
          total: map() | nil
        }

  @type availability_detail :: %{
          notAvailableReason: String.t(),
          date: datetime()
        }

  @type availability :: %{
          available: boolean(),
          details: list(availability_detail())
        }

  @type search_result :: %{
          property: property(),
          pricing: pricing(),
          availability: availability(),
          distance_in_km: float()
        }

  @type properties_response :: %{
          data: list(property()),
          links: map(),
          meta: map()
        }

  @type search_response :: %{
          data: list(search_result())
        }

  @type get_properties_opts :: [
          include: String.t(),
          page: integer(),
          per_page: integer()
        ]

  @type location :: %{
          latitude: float(),
          longitude: float()
        }

  @type search_properties_opts :: [
          adults: integer(),
          start_date: date(),
          end_date: date(),
          children: integer(),
          infants: integer(),
          pets: integer(),
          include: String.t(),
          location: location()
        ]

  @doc """
  Retrieves all properties with optional pagination and includes.

  ## Parameters
  - `config`: Client configuration with API key and base URL
  - `opts`: Query options (see `t:get_properties_opts/0`)

  ## Options
  - `:include` - Comma-separated includes (e.g., "user,listings,details,bookings")
  - `:page` - Page number for pagination (default: 1)
  - `:per_page` - Results per page, max 100 (default: 10)

  ## Available Includes
  - `user` - User information
  - `listings` - Listing information (requires `listing:read` scope)
  - `details` - Detailed property information
  - `bookings` - Booking policies and pricing information

  ## Examples

      iex> config = HospitableClient.new("api-key")
      iex> # This would make an actual API request:
      iex> # {:ok, response} = HospitableClient.Properties.get_properties(config,
      iex> #   include: "user,listings,details",
      iex> #   page: 1,
      iex> #   per_page: 50
      iex> # )
      iex> config.api_key
      "api-key"

  """
  @spec get_properties(config(), get_properties_opts()) ::
          {:ok, properties_response()} | {:error, term()}
  def get_properties(config, opts \\ []) do
    query_params = build_properties_query(opts)
    base_path = "#{@base_url}/properties"
    url = if query_params == "", do: base_path, else: "#{base_path}?#{query_params}"
    headers = HospitableClient.Auth.headers(config.api_key)

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, {:http_error, status_code, body}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end

  @doc """
  Searches for available properties based on dates, location, and guest requirements.

  ## Parameters
  - `config`: Client configuration with API key and base URL
  - `opts`: Search options (see `t:search_properties_opts/0`)

  ## Required Options
  - `:adults` - Number of adult guests
  - `:start_date` - Check-in date (YYYY-MM-DD format)
  - `:end_date` - Check-out date (YYYY-MM-DD format)

  ## Optional Options
  - `:children` - Number of children
  - `:infants` - Number of infants
  - `:pets` - Number of pets
  - `:include` - Comma-separated includes (e.g., "listings,details")
  - `:location` - Map with `:latitude` and `:longitude` keys for proximity search

  ## Available Includes
  - `listings` - Listing information (requires `listing:read` scope)
  - `details` - Detailed property information

  ## Requirements
  - Customer must have a Self-hosted site created in Direct with properties scoped
  - Search limitations: Up to 3 years in the future, maximum period of 90 days

  ## Examples

      iex> config = HospitableClient.new("api-key")
      iex> # This would make an actual API request:
      iex> # {:ok, response} = HospitableClient.Properties.search_properties(config,
      iex> #   adults: 2,
      iex> #   children: 1,
      iex> #   start_date: "2024-08-16",
      iex> #   end_date: "2024-08-21",
      iex> #   include: "listings,details"
      iex> # )
      iex> config.api_key
      "api-key"

  """
  @spec search_properties(config(), search_properties_opts()) ::
          {:ok, search_response()} | {:error, term()}
  def search_properties(config, opts \\ []) do
    required_params = [:adults, :start_date, :end_date]

    for param <- required_params do
      unless Keyword.has_key?(opts, param) do
        raise ArgumentError, "#{param} parameter is required for property search"
      end
    end

    # Validate date range (up to 3 years in the future, max 90 days period)
    case validate_search_dates(opts[:start_date], opts[:end_date]) do
      :ok -> :ok
      {:error, reason} -> raise ArgumentError, reason
    end

    query_params = build_search_query(opts)
    url = "#{@base_url}/properties/search?" <> query_params
    headers = HospitableClient.Auth.headers(config.api_key)

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, {:http_error, status_code, body}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end

  @doc """
  Checks if a property allows pets based on house rules.

  ## Parameters
  - `property`: The property map

  ## Examples

      iex> property = %{house_rules: %{pets_allowed: true}}
      iex> HospitableClient.Properties.pet_friendly?(property)
      true

      iex> property = %{house_rules: %{pets_allowed: false}}
      iex> HospitableClient.Properties.pet_friendly?(property)
      false

  """
  @spec pet_friendly?(property()) :: boolean()
  def pet_friendly?(%{house_rules: %{pets_allowed: pets_allowed}}), do: pets_allowed
  def pet_friendly?(_), do: false

  @doc """
  Checks if a property allows smoking based on house rules.

  ## Parameters
  - `property`: The property map

  ## Examples

      iex> property = %{house_rules: %{smoking_allowed: true}}
      iex> HospitableClient.Properties.smoking_allowed?(property)
      true

      iex> property = %{house_rules: %{smoking_allowed: false}}
      iex> HospitableClient.Properties.smoking_allowed?(property)
      false

  """
  @spec smoking_allowed?(property()) :: boolean()
  def smoking_allowed?(%{house_rules: %{smoking_allowed: smoking_allowed}}), do: smoking_allowed
  def smoking_allowed?(_), do: false

  @doc """
  Checks if a property allows events based on house rules.

  ## Parameters
  - `property`: The property map

  ## Examples

      iex> property = %{house_rules: %{events_allowed: true}}
      iex> HospitableClient.Properties.events_allowed?(property)
      true

      iex> property = %{house_rules: %{events_allowed: false}}
      iex> HospitableClient.Properties.events_allowed?(property)
      false

      iex> property = %{house_rules: %{events_allowed: nil}}
      iex> HospitableClient.Properties.events_allowed?(property)
      false

  """
  @spec events_allowed?(property()) :: boolean()
  def events_allowed?(%{house_rules: %{events_allowed: true}}), do: true
  def events_allowed?(_), do: false

  @doc """
  Checks if a property is currently listed on any platform.

  ## Parameters
  - `property`: The property map

  ## Examples

      iex> property = %{listed: true}
      iex> HospitableClient.Properties.listed?(property)
      true

      iex> property = %{listed: false}
      iex> HospitableClient.Properties.listed?(property)
      false

  """
  @spec listed?(property()) :: boolean()
  def listed?(%{listed: listed}), do: listed
  def listed?(_), do: false

  @doc """
  Gets the maximum guest capacity for a property.

  ## Parameters
  - `property`: The property map

  ## Examples

      iex> property = %{capacity: %{max: 4}}
      iex> HospitableClient.Properties.max_guests(property)
      4

      iex> property = %{}
      iex> HospitableClient.Properties.max_guests(property)
      0

  """
  @spec max_guests(property()) :: integer()
  def max_guests(%{capacity: %{max: max}}), do: max
  def max_guests(_), do: 0

  @doc """
  Checks if a search result property is available for the searched dates.

  ## Parameters
  - `search_result`: The search result map

  ## Examples

      iex> search_result = %{availability: %{available: true}}
      iex> HospitableClient.Properties.available?(search_result)
      true

      iex> search_result = %{availability: %{available: false}}
      iex> HospitableClient.Properties.available?(search_result)
      false

  """
  @spec available?(search_result()) :: boolean()
  def available?(%{availability: %{available: available}}), do: available
  def available?(_), do: false

  @doc """
  Gets the unavailability reasons for a search result.

  ## Parameters
  - `search_result`: The search result map

  ## Examples

      iex> search_result = %{availability: %{details: [%{notAvailableReason: "booked"}]}}
      iex> HospitableClient.Properties.unavailability_reasons(search_result)
      ["booked"]

  """
  @spec unavailability_reasons(search_result()) :: list(String.t())
  def unavailability_reasons(%{availability: %{details: details}}) do
    Enum.map(details, & &1.notAvailableReason)
  end

  def unavailability_reasons(_), do: []

  # Private helper functions

  defp build_properties_query(opts) do
    opts
    |> Enum.filter(fn {_key, value} -> not is_nil(value) end)
    |> Enum.map(fn {key, value} -> "#{key}=#{URI.encode(to_string(value))}" end)
    |> Enum.join("&")
  end

  defp build_search_query(opts) do
    # Handle location parameter specially (deepObject style)
    {location_params, other_opts} = extract_location_params(opts)

    other_params =
      other_opts
      |> Enum.filter(fn {_key, value} -> not is_nil(value) end)
      |> Enum.map(fn {key, value} -> "#{key}=#{URI.encode(to_string(value))}" end)
      |> Enum.join("&")

    case {location_params, other_params} do
      {"", ""} -> ""
      {loc, ""} -> loc
      {"", others} -> others
      {loc, others} -> "#{others}&#{loc}"
    end
  end

  defp extract_location_params(opts) do
    case Keyword.get(opts, :location) do
      %{latitude: lat, longitude: lng} ->
        location_params = "location[latitude]=#{lat}&location[longitude]=#{lng}"
        other_opts = Keyword.delete(opts, :location)
        {location_params, other_opts}

      _ ->
        {"", opts}
    end
  end

  defp validate_search_dates(start_date, end_date) do
    with {:ok, start_date} <- Date.from_iso8601(start_date),
         {:ok, end_date} <- Date.from_iso8601(end_date) do
      today = Date.utc_today()
      three_years_from_now = Date.add(today, 365 * 3)
      days_diff = Date.diff(end_date, start_date)

      cond do
        Date.compare(start_date, today) == :lt ->
          {:error, "start_date cannot be in the past"}

        Date.compare(end_date, start_date) != :gt ->
          {:error, "end_date must be after start_date"}

        Date.compare(start_date, three_years_from_now) == :gt ->
          {:error, "start_date cannot be more than 3 years in the future"}

        days_diff > 90 ->
          {:error, "search period cannot exceed 90 days"}

        true ->
          :ok
      end
    else
      _ -> {:error, "invalid date format, use YYYY-MM-DD"}
    end
  end
end