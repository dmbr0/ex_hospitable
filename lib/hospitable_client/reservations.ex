defmodule HospitableClient.Reservations do
  @moduledoc """
  Module for managing reservations through the Hospitable API.

  This module provides functions for retrieving and managing reservations,
  including support for date filtering, financial data, guest information,
  and platform-specific operations.

  ## Available Include Options

  When fetching reservations, you can include related resources using the `include` parameter:
  - `"financials"` - Include financial breakdown for guest and host
  - `"financialsV2"` - Include enhanced financial data (v2 format)
  - `"guest"` - Include detailed guest information
  - `"properties"` - Include property details
  - `"listings"` - Include platform listing information

  Multiple includes can be combined: `"financials,guest,properties"`

  ## Date Filtering

  The API supports sophisticated date filtering:
  - `date_query` - Filter by `"checkin"` or `"checkout"` dates (default: `"checkin"`)
  - `start_date` and `end_date` - Define date range
  - If no date filters provided, defaults to check-in dates in the next 2 weeks

  ## Usage

      # Get reservations for specific properties
      {:ok, reservations} = HospitableClient.Reservations.get_reservations(%{
        properties: ["property-uuid-1", "property-uuid-2"]
      })

      # Get reservations with date filtering
      {:ok, reservations} = HospitableClient.Reservations.get_reservations(%{
        properties: ["property-uuid-1"],
        date_query: "checkin",
        start_date: "2024-01-01",
        end_date: "2024-01-31"
      })

      # Get reservations with financial and guest data
      {:ok, reservations} = HospitableClient.Reservations.get_reservations(%{
        properties: ["property-uuid-1"],
        include: "financials,guest,properties"
      })

  """

  alias HospitableClient.HTTP.Client

  # Valid include options as per API specification
  @valid_includes ~w(financials financialsV2 guest properties listings)

  # Valid date query options
  @valid_date_queries ~w(checkin checkout)


  @doc """
  Retrieves a paginated list of reservations.

  ## Parameters

  - `opts` - A map of options for the request

  ## Required Options

  - `:properties` - List of property IDs (required)

  ## Optional Options

  - `:conversation_id` - Filter by conversation UUID
  - `:date_query` - Filter by "checkin" or "checkout" dates (default: "checkin")
  - `:start_date` - Start date for filtering (YYYY-MM-DD format)
  - `:end_date` - End date for filtering (YYYY-MM-DD format)
  - `:include` - Related resources to include. Valid values: #{inspect(@valid_includes)}
  - `:last_message_at` - Filter by last message timestamp
  - `:page` - Page of results (default: 1)
  - `:per_page` - Results per page, max 100 (default: 10)
  - `:platform_id` - Filter by platform-specific reservation ID

  ## Examples

      # Basic reservation retrieval
      iex> HospitableClient.Reservations.get_reservations(%{
        properties: ["550e8400-e29b-41d4-a716-446655440000"]
      })
      {:ok, %{
        "data" => [
          %{
            "id" => "reservation-uuid",
            "conversation_id" => "conversation-uuid",
            "platform" => "airbnb",
            "platform_id" => "HM123456789",
            "booking_date" => "2024-01-15T10:30:00Z",
            "arrival_date" => "2024-02-01T16:00:00Z",
            "departure_date" => "2024-02-05T11:00:00Z",
            "nights" => 4,
            "check_in" => "2024-02-01T16:00:00Z",
            "check_out" => "2024-02-05T11:00:00Z",
            "reservation_status" => %{...},
            "guests" => %{...}
          }
        ],
        "links" => %{...},
        "meta" => %{...}
      }}

      # With date filtering
      iex> HospitableClient.Reservations.get_reservations(%{
        properties: ["550e8400-e29b-41d4-a716-446655440000"],
        date_query: "checkin",
        start_date: "2024-02-01",
        end_date: "2024-02-28"
      })

      # With financial and guest includes
      iex> HospitableClient.Reservations.get_reservations(%{
        properties: ["550e8400-e29b-41d4-a716-446655440000"],
        include: "financials,guest,properties"
      })

  ## Default Behavior

  If no date filters are provided, the API defaults to reservations with
  check-in dates in the next 2 weeks.

  """
  @spec get_reservations(map()) :: {:ok, map()} | {:error, term()}
  def get_reservations(opts) when is_map(opts) do
    with {:ok, validated_opts} <- validate_options(opts),
         params <- build_query_params(validated_opts) do
      Client.get("/reservations", params)
    end
  end

  @doc """
  Gets all reservations across all pages.

  This function automatically handles pagination and returns all reservations
  in a single response. Use with caution for accounts with many reservations.

  ## Parameters

  - `opts` - A map of options for the request (same as get_reservations/1)

  ## Options

  - All options from `get_reservations/1`
  - `:max_pages` - Maximum number of pages to fetch (default: 20, safety limit)

  ## Examples

      iex> HospitableClient.Reservations.get_all_reservations(%{
        properties: ["property-uuid"],
        include: "financials,guest"
      })
      {:ok, %{
        "data" => [...],  # All reservations across all pages
        "meta" => %{
          "total_pages" => 3,
          "total_reservations" => 67,
          "fetched_pages" => 3
        }
      }}

  """
  @spec get_all_reservations(map()) :: {:ok, map()} | {:error, term()}
  def get_all_reservations(opts) when is_map(opts) do
    with {:ok, validated_opts} <- validate_options(opts) do
      per_page = Map.get(validated_opts, :per_page, 100)
      max_pages = Map.get(validated_opts, :max_pages, 20)

      # Ensure per_page doesn't exceed API limit
      per_page = min(per_page, 100)

      initial_opts = validated_opts
      |> Map.put(:page, 1)
      |> Map.put(:per_page, per_page)

      case get_reservations(initial_opts) do
        {:ok, first_response} ->
          fetch_remaining_pages(first_response, validated_opts, per_page, max_pages, 1)

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Extracts unique platforms from a set of reservations.

  ## Examples

      iex> {:ok, response} = HospitableClient.Reservations.get_reservations(%{properties: ["uuid"]})
      iex> platforms = HospitableClient.Reservations.list_platforms(response)
      ["airbnb", "booking", "direct"]

  """
  @spec list_platforms(map() | list()) :: list(String.t())
  def list_platforms(%{"data" => reservations}) when is_list(reservations) do
    list_platforms(reservations)
  end

  def list_platforms(reservations) when is_list(reservations) do
    reservations
    |> Enum.map(fn reservation -> Map.get(reservation, "platform") end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Extracts unique reservation statuses from a set of reservations.

  ## Examples

      iex> statuses = HospitableClient.Reservations.list_statuses(response)
      ["confirmed", "pending", "cancelled"]

  """
  @spec list_statuses(map() | list()) :: list(String.t())
  def list_statuses(%{"data" => reservations}) when is_list(reservations) do
    list_statuses(reservations)
  end

  def list_statuses(reservations) when is_list(reservations) do
    reservations
    |> Enum.map(fn reservation ->
      case get_in(reservation, ["reservation_status"]) do
        %{"status" => status} -> status
        status when is_binary(status) -> status
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Calculates total nights across reservations.

  ## Examples

      iex> total_nights = HospitableClient.Reservations.total_nights(response)
      45

  """
  @spec total_nights(map() | list()) :: integer()
  def total_nights(%{"data" => reservations}) when is_list(reservations) do
    total_nights(reservations)
  end

  def total_nights(reservations) when is_list(reservations) do
    reservations
    |> Enum.map(fn reservation -> Map.get(reservation, "nights", 0) end)
    |> Enum.sum()
  end

  @doc """
  Calculates total revenue from reservations with financial data.

  Returns revenue in the specified currency or all currencies if none specified.

  ## Parameters

  - `reservations` - List of reservations or response map
  - `currency` - Optional currency filter (e.g., "USD", "EUR")

  ## Examples

      iex> revenue = HospitableClient.Reservations.total_revenue(response)
      %{"USD" => 15420, "EUR" => 8930}

      iex> usd_revenue = HospitableClient.Reservations.total_revenue(response, "USD")
      15420

  """
  @spec total_revenue(map() | list(), String.t() | nil) :: map() | integer()
  def total_revenue(data, currency \\ nil)

  def total_revenue(%{"data" => reservations}, currency) when is_list(reservations) do
    total_revenue(reservations, currency)
  end

  def total_revenue(reservations, currency) when is_list(reservations) do
    revenue_by_currency =
      reservations
      |> Enum.reduce(%{}, fn reservation, acc ->
        case extract_revenue(reservation) do
          {res_currency, amount} ->
            Map.update(acc, res_currency, amount, &(&1 + amount))
          nil ->
            acc
        end
      end)

    case currency do
      nil -> revenue_by_currency
      specific_currency -> Map.get(revenue_by_currency, specific_currency, 0)
    end
  end

  @doc """
  Filters reservations by specific criteria.

  ## Parameters

  - `reservations` - List of reservation maps or a response map with data key
  - `filters` - Map of filter criteria

  ## Filter Options

  **Basic Filters:**
  - `:platform` - Filter by platform ("airbnb", "booking", etc.)
  - `:stay_type` - Filter by stay type ("guest_stay", "owner_stay")
  - `:has_guest_info` - Filter reservations with guest information (true/false)

  **Date Filters:**
  - `:arriving_after` - Filter by arrival date after specified date
  - `:arriving_before` - Filter by arrival date before specified date
  - `:departing_after` - Filter by departure date after specified date
  - `:departing_before` - Filter by departure date before specified date
  - `:min_nights` - Filter by minimum number of nights
  - `:max_nights` - Filter by maximum number of nights

  **Financial Filters:**
  - `:min_revenue` - Filter by minimum revenue amount
  - `:max_revenue` - Filter by maximum revenue amount
  - `:currency` - Filter by financial currency

  **Status Filters:**
  - `:status` - Filter by reservation status

  ## Examples

      iex> {:ok, response} = HospitableClient.Reservations.get_reservations(%{properties: ["uuid"]})

      # Filter by platform
      iex> airbnb_reservations = HospitableClient.Reservations.filter_reservations(response, %{
        platform: "airbnb"
      })

      # Filter by date range
      iex> february_arrivals = HospitableClient.Reservations.filter_reservations(response, %{
        arriving_after: ~D[2024-02-01],
        arriving_before: ~D[2024-02-29]
      })

      # Filter by stay length and revenue
      iex> long_valuable_stays = HospitableClient.Reservations.filter_reservations(response, %{
        min_nights: 7,
        min_revenue: 1000,
        currency: "USD"
      })

  """
  @spec filter_reservations(map() | list(), map()) :: list(map())
  def filter_reservations(%{"data" => reservations}, filters) when is_list(reservations) do
    filter_reservations(reservations, filters)
  end

  def filter_reservations(reservations, filters) when is_list(reservations) and is_map(filters) do
    Enum.filter(reservations, fn reservation ->
      passes_all_filters?(reservation, filters)
    end)
  end

  @doc """
  Groups reservations by a specific field.

  ## Parameters

  - `reservations` - List of reservations or response map
  - `group_by` - Field to group by (:platform, :month, :year, :property_id, :status)

  ## Examples

      iex> by_platform = HospitableClient.Reservations.group_reservations(response, :platform)
      %{
        "airbnb" => [...],
        "booking" => [...],
        "direct" => [...]
      }

      iex> by_month = HospitableClient.Reservations.group_reservations(response, :month)
      %{
        "2024-01" => [...],
        "2024-02" => [...]
      }

  """
  @spec group_reservations(map() | list(), atom()) :: map()
  def group_reservations(%{"data" => reservations}, group_by) when is_list(reservations) do
    group_reservations(reservations, group_by)
  end

  def group_reservations(reservations, group_by) when is_list(reservations) and is_atom(group_by) do
    case group_by do
      :platform ->
        Enum.group_by(reservations, fn r -> Map.get(r, "platform", "unknown") end)
      :month ->
        Enum.group_by(reservations, &extract_arrival_month/1)
      :year ->
        Enum.group_by(reservations, &extract_arrival_year/1)
      :property_id ->
        Enum.group_by(reservations, &extract_property_id/1)
      :status ->
        Enum.group_by(reservations, &extract_status/1)
      field_name ->
        field_str = Atom.to_string(field_name)
        Enum.group_by(reservations, fn r -> Map.get(r, field_str, "unknown") end)
    end
  end

  @doc """
  Generates a financial summary from reservations with financial data.

  ## Examples

      iex> summary = HospitableClient.Reservations.financial_summary(response)
      %{
        "USD" => %{
          "total_revenue" => 15420,
          "total_guest_fees" => 1200,
          "total_host_fees" => 850,
          "average_per_night" => 89.50,
          "reservation_count" => 12
        },
        "EUR" => %{...}
      }

  """
  @spec financial_summary(map() | list()) :: map()
  def financial_summary(%{"data" => reservations}) when is_list(reservations) do
    financial_summary(reservations)
  end

  def financial_summary(reservations) when is_list(reservations) do
    reservations
    |> Enum.reduce(%{}, fn reservation, acc ->
      case extract_financial_details(reservation) do
        nil -> acc
        financial_data -> merge_financial_data(acc, financial_data)
      end
    end)
    |> calculate_financial_averages()
  end

  @doc """
  Validates if a list of property IDs are in valid UUID format.

  ## Examples

      iex> HospitableClient.Reservations.valid_property_ids?(["550e8400-e29b-41d4-a716-446655440000"])
      true

      iex> HospitableClient.Reservations.valid_property_ids?(["invalid-id"])
      false

  """
  @spec valid_property_ids?(list(String.t())) :: boolean()
  def valid_property_ids?(property_ids) when is_list(property_ids) do
    Enum.all?(property_ids, fn id ->
      HospitableClient.Properties.valid_uuid?(id)
    end)
  end

  @doc """
  Creates a date range for the next N weeks (default behavior simulation).

  ## Examples

      iex> {start_date, end_date} = HospitableClient.Reservations.next_weeks_range(2)
      {~D[2024-08-18], ~D[2024-09-01]}

  """
  @spec next_weeks_range(integer()) :: {Date.t(), Date.t()}
  def next_weeks_range(weeks \\ 2) do
    today = Date.utc_today()
    end_date = Date.add(today, weeks * 7)
    {today, end_date}
  end

  # Private Functions

  defp validate_options(opts) when is_map(opts) do
    with {:ok, _} <- validate_required_properties(opts),
         {:ok, validated_opts} <- validate_include_option(opts),
         {:ok, validated_opts} <- validate_date_query_option(validated_opts),
         {:ok, validated_opts} <- validate_date_format(validated_opts) do
      {:ok, validated_opts}
    end
  end

  defp validate_required_properties(opts) do
    case Map.get(opts, :properties) do
      properties when is_list(properties) and length(properties) > 0 ->
        if valid_property_ids?(properties) do
          {:ok, properties}
        else
          {:error, {:invalid_property_ids, "All property IDs must be valid UUIDs"}}
        end
      _ ->
        {:error, {:missing_properties, "properties parameter is required and must be a non-empty list"}}
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

  defp validate_date_query_option(opts) do
    case Map.get(opts, :date_query) do
      nil ->
        {:ok, opts}
      date_query when date_query in @valid_date_queries ->
        {:ok, opts}
      invalid_date_query ->
        {:error, {:invalid_date_query, invalid_date_query, @valid_date_queries}}
    end
  end

  defp validate_date_format(opts) do
    date_fields = [:start_date, :end_date]

    Enum.reduce_while(date_fields, {:ok, opts}, fn field, {:ok, acc_opts} ->
      case Map.get(acc_opts, field) do
        nil ->
          {:cont, {:ok, acc_opts}}
        date_string when is_binary(date_string) ->
          case Date.from_iso8601(date_string) do
            {:ok, _date} -> {:cont, {:ok, acc_opts}}
            {:error, _} -> {:halt, {:error, {:invalid_date_format, field, "Must be in YYYY-MM-DD format"}}}
          end
        _ ->
          {:halt, {:error, {:invalid_date_type, field, "Must be a string in YYYY-MM-DD format"}}}
      end
    end)
  end

  defp build_query_params(opts) do
    # Handle properties array specially
    properties_param = case Map.get(opts, :properties) do
      properties when is_list(properties) ->
        # Convert to properties[] format expected by API
        properties
        |> Enum.with_index()
        |> Enum.into(%{}, fn {property_id, index} ->
          {"properties[#{index}]", property_id}
        end)
      _ -> %{}
    end

    # Handle other parameters
    other_params = opts
    |> Map.drop([:properties])
    |> Map.take([:conversation_id, :date_query, :end_date, :include, :last_message_at,
                 :page, :per_page, :platform_id, :start_date])
    |> Enum.into(%{}, fn {key, value} -> {Atom.to_string(key), value} end)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into(%{})

    Map.merge(properties_param, other_params)
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
          "total_reservations" => total,
          "fetched_pages" => current_page
        }
      }}
    else
      # Fetch next page
      next_page = current_page + 1
      next_opts = opts
      |> Map.put(:page, next_page)
      |> Map.put(:per_page, per_page)

      case get_reservations(next_opts) do
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
              "total_reservations" => total,
              "fetched_pages" => current_page,
              "error" => "Failed to fetch page #{next_page}: #{inspect(reason)}"
            }
          }}
      end
    end
  end

  defp passes_all_filters?(reservation, filters) do
    Enum.all?(filters, fn {filter_key, filter_value} ->
      passes_filter?(reservation, filter_key, filter_value)
    end)
  end

  # Basic filters
  defp passes_filter?(reservation, :platform, expected_platform) do
    Map.get(reservation, "platform") == expected_platform
  end

  defp passes_filter?(reservation, :stay_type, expected_stay_type) do
    Map.get(reservation, "stay_type") == expected_stay_type
  end

  defp passes_filter?(reservation, :has_guest_info, expected_value) do
    has_guest = case Map.get(reservation, "guest") do
      nil -> false
      guest when is_map(guest) -> !Enum.empty?(guest)
      _ -> true
    end
    has_guest == expected_value
  end

  defp passes_filter?(reservation, :status, expected_status) do
    extract_status(reservation) == expected_status
  end

  # Date filters
  defp passes_filter?(reservation, :arriving_after, date) do
    case parse_date_field(reservation, "arrival_date") do
      {:ok, arrival_date} -> Date.compare(arrival_date, date) in [:gt, :eq]
      {:error, _} -> false
    end
  end

  defp passes_filter?(reservation, :arriving_before, date) do
    case parse_date_field(reservation, "arrival_date") do
      {:ok, arrival_date} -> Date.compare(arrival_date, date) in [:lt, :eq]
      {:error, _} -> false
    end
  end

  defp passes_filter?(reservation, :departing_after, date) do
    case parse_date_field(reservation, "departure_date") do
      {:ok, departure_date} -> Date.compare(departure_date, date) in [:gt, :eq]
      {:error, _} -> false
    end
  end

  defp passes_filter?(reservation, :departing_before, date) do
    case parse_date_field(reservation, "departure_date") do
      {:ok, departure_date} -> Date.compare(departure_date, date) in [:lt, :eq]
      {:error, _} -> false
    end
  end

  defp passes_filter?(reservation, :min_nights, min_nights) do
    nights = Map.get(reservation, "nights", 0)
    nights >= min_nights
  end

  defp passes_filter?(reservation, :max_nights, max_nights) do
    nights = Map.get(reservation, "nights", 0)
    nights <= max_nights
  end

  # Financial filters
  defp passes_filter?(reservation, :min_revenue, min_revenue) do
    case extract_revenue(reservation) do
      {_currency, amount} -> amount >= min_revenue
      nil -> false
    end
  end

  defp passes_filter?(reservation, :max_revenue, max_revenue) do
    case extract_revenue(reservation) do
      {_currency, amount} -> amount <= max_revenue
      nil -> false
    end
  end

  defp passes_filter?(reservation, :currency, expected_currency) do
    case extract_revenue(reservation) do
      {currency, _amount} -> currency == expected_currency
      nil -> false
    end
  end

  defp passes_filter?(_reservation, _filter_key, _filter_value) do
    # Unknown filter, don't filter out the reservation
    true
  end

  # Data extraction helpers
  defp extract_revenue(reservation) do
    case get_in(reservation, ["financials", "host", "revenue"]) do
      %{"amount" => amount} when is_integer(amount) ->
        currency = get_in(reservation, ["financials", "currency"]) || "USD"
        {currency, amount}
      _ -> nil
    end
  end

  defp extract_financial_details(reservation) do
    case Map.get(reservation, "financials") do
      nil -> nil
      financials ->
        currency = Map.get(financials, "currency", "USD")
        nights = Map.get(reservation, "nights", 1)

        %{
          currency: currency,
          nights: nights,
          revenue: extract_financial_amount(financials, ["host", "revenue"]),
          guest_total: extract_financial_amount(financials, ["guest", "total_price"]),
          guest_fees: extract_financial_array_total(financials, ["guest", "fees"]),
          host_fees: extract_financial_array_total(financials, ["host", "host_fees"])
        }
    end
  end

  defp extract_financial_amount(financials, path) do
    case get_in(financials, path) do
      %{"amount" => amount} when is_integer(amount) -> amount
      _ -> 0
    end
  end

  defp extract_financial_array_total(financials, path) do
    case get_in(financials, path) do
      fees when is_list(fees) ->
        fees
        |> Enum.map(fn fee -> Map.get(fee, "amount", 0) end)
        |> Enum.sum()
      _ -> 0
    end
  end

  defp merge_financial_data(acc, financial_data) do
    currency = financial_data.currency

    Map.update(acc, currency, financial_data, fn existing ->
      %{
        currency: currency,
        nights: existing.nights + financial_data.nights,
        revenue: existing.revenue + financial_data.revenue,
        guest_total: existing.guest_total + financial_data.guest_total,
        guest_fees: existing.guest_fees + financial_data.guest_fees,
        host_fees: existing.host_fees + financial_data.host_fees,
        reservation_count: Map.get(existing, :reservation_count, 1) + 1
      }
    end)
  end

  defp calculate_financial_averages(financial_data) do
    Enum.into(financial_data, %{}, fn {currency, data} ->
      nights = data.nights
      count = Map.get(data, :reservation_count, 1)

      averages = %{
        "total_revenue" => data.revenue,
        "total_guest_fees" => data.guest_fees,
        "total_host_fees" => data.host_fees,
        "average_per_night" => if(nights > 0, do: Float.round(data.revenue / nights, 2), else: 0),
        "average_per_reservation" => if(count > 0, do: Float.round(data.revenue / count, 2), else: 0),
        "reservation_count" => count,
        "total_nights" => nights
      }

      {currency, averages}
    end)
  end

  defp extract_arrival_month(reservation) do
    case parse_date_field(reservation, "arrival_date") do
      {:ok, date} -> "#{date.year}-#{String.pad_leading(to_string(date.month), 2, "0")}"
      {:error, _} -> "unknown"
    end
  end

  defp extract_arrival_year(reservation) do
    case parse_date_field(reservation, "arrival_date") do
      {:ok, date} -> to_string(date.year)
      {:error, _} -> "unknown"
    end
  end

  defp extract_property_id(reservation) do
    # Try to extract property ID from various possible locations
    case get_in(reservation, ["properties"]) do
      [%{"id" => property_id} | _] -> property_id
      _ -> "unknown"
    end
  end

  defp extract_status(reservation) do
    case get_in(reservation, ["reservation_status"]) do
      %{"status" => status} -> status
      status when is_binary(status) -> status
      _ -> "unknown"
    end
  end

  defp parse_date_field(reservation, field) do
    case Map.get(reservation, field) do
      date_string when is_binary(date_string) ->
        case DateTime.from_iso8601(date_string) do
          {:ok, datetime, _offset} -> {:ok, DateTime.to_date(datetime)}
          {:error, _} ->
            case Date.from_iso8601(date_string) do
              {:ok, date} -> {:ok, date}
              error -> error
            end
        end
      _ -> {:error, :invalid_date}
    end
  end
end
