defmodule HospitableClient.Reservations do
  @moduledoc """
  Reservations API functionality for the Hospitable client.
  
  This module provides functions to interact with reservation endpoints,
  including fetching multiple reservations and individual reservations by UUID.
  """

  @base_url "https://public.api.hospitable.com/v2"

  @type config :: HospitableClient.Config.config()
  @type uuid :: String.t()
  @type date :: String.t()
  @type datetime :: String.t()

  @type reservation_status :: %{
          current: %{
            category: String.t(),
            sub_category: String.t() | nil
          },
          history: list(%{
            category: String.t(),
            sub_category: String.t() | nil,
            changed_at: datetime()
          })
        }

  @type guests_info :: %{
          total: integer(),
          adult_count: integer(),
          child_count: integer(),
          infant_count: integer(),
          pet_count: integer()
        }

  @type financial_line_item :: %{
          amount: integer(),
          formatted: String.t(),
          label: String.t(),
          category: String.t()
        }

  @type financial_data :: %{
          guest: %{
            accommodation: financial_line_item(),
            fees: list(financial_line_item()),
            discounts: list(financial_line_item()),
            taxes: list(financial_line_item()),
            adjustments: list(financial_line_item()),
            total_price: financial_line_item()
          },
          host: %{
            accommodation: financial_line_item(),
            accommodation_breakdown: list(financial_line_item()),
            guest_fees: list(financial_line_item()),
            host_fees: list(financial_line_item()),
            discounts: list(financial_line_item()),
            adjustments: list(financial_line_item()),
            taxes: list(financial_line_item()),
            revenue: financial_line_item()
          },
          currency: String.t()
        }

  @type guest :: %{
          id: String.t(),
          profile_picture: String.t(),
          location: String.t(),
          first_name: String.t(),
          last_name: String.t(),
          email: String.t(),
          phone_numbers: list(String.t())
        }

  @type property :: %{
          id: uuid(),
          name: String.t(),
          public_name: String.t(),
          picture: String.t(),
          address: map(),
          timezone: String.t(),
          listed: boolean(),
          amenities: list(String.t()),
          description: String.t(),
          summary: String.t(),
          currency: String.t(),
          capacity: map(),
          room_details: list(map()),
          house_rules: map(),
          listings: list(map()),
          tags: list(String.t()),
          property_type: String.t(),
          room_type: String.t(),
          calendar_restricted: boolean()
        }

  @type review :: %{
          id: uuid(),
          platform: String.t(),
          public: map(),
          private: map(),
          responded_at: datetime(),
          reviewed_at: datetime(),
          can_respond: boolean()
        }

  @type reservation :: %{
          id: uuid(),
          conversation_id: uuid(),
          platform: String.t(),
          platform_id: String.t(),
          booking_date: datetime(),
          arrival_date: datetime(),
          departure_date: datetime(),
          nights: integer(),
          check_in: datetime(),
          check_out: datetime(),
          last_message_at: datetime(),
          status: String.t(),
          reservation_status: reservation_status(),
          guests: guests_info(),
          issue_alert: String.t() | nil,
          stay_type: String.t(),
          financials: financial_data() | nil,
          properties: list(property()) | nil,
          listings: list(map()) | nil,
          guest: guest() | nil,
          user: map() | nil,
          review: review() | nil
        }

  @type reservations_response :: %{
          data: list(reservation()),
          links: map(),
          meta: map()
        }

  @type reservation_response :: %{
          data: reservation()
        }

  @type get_reservations_opts :: [
          properties: list(uuid()),
          conversation_id: String.t(),
          date_query: String.t(),
          start_date: date(),
          end_date: date(),
          include: String.t(),
          last_message_at: datetime(),
          page: integer(),
          per_page: integer(),
          platform_id: String.t()
        ]

  @type get_reservation_opts :: [
          include: String.t()
        ]

  @doc """
  Retrieves multiple reservations with optional filtering and pagination.

  ## Parameters
  - `config`: Client configuration with API key and base URL
  - `opts`: Query options (see `t:get_reservations_opts/0`)

  ## Required Options
  - `:properties` - List of property UUIDs to query

  ## Optional Options
  - `:conversation_id` - Find reservations matching exact conversation ID
  - `:date_query` - Search by 'checkin' or 'checkout' dates (default: "checkin")
  - `:start_date` - Find reservations after this date (YYYY-MM-DD format)
  - `:end_date` - Find reservations before this date (YYYY-MM-DD format)
  - `:include` - Comma-separated includes (e.g., "financials,guest,properties")
  - `:last_message_at` - Find reservations with messages after datetime
  - `:page` - Page number for pagination (default: 1)
  - `:per_page` - Results per page, max 100 (default: 10)
  - `:platform_id` - Find by exact reservation code

  ## Examples

      iex> config = HospitableClient.new("api-key")
      iex> # This would make an actual API request:
      iex> # {:ok, response} = HospitableClient.Reservations.get_reservations(config, 
      iex> #   properties: ["prop-uuid-1", "prop-uuid-2"],
      iex> #   include: "financials,guest,properties",
      iex> #   page: 1,
      iex> #   per_page: 20
      iex> # )
      iex> config.api_key
      "api-key"

  """
  @spec get_reservations(config(), get_reservations_opts()) ::
          {:ok, reservations_response()} | {:error, term()}
  def get_reservations(config, opts \\ []) do
    unless Keyword.has_key?(opts, :properties) do
      raise ArgumentError, "properties parameter is required"
    end

    query_params = build_reservations_query(opts)
    url = "#{@base_url}/reservations?" <> query_params
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
  Retrieves a specific reservation by its UUID.

  ## Parameters
  - `config`: Client configuration with API key and base URL
  - `uuid`: The UUID of the reservation to retrieve
  - `opts`: Query options (see `t:get_reservation_opts/0`)

  ## Options
  - `:include` - Comma-separated includes (e.g., "financials,guest,properties,review")

  ## Examples

      iex> config = HospitableClient.new("api-key")
      iex> # This would make an actual API request:
      iex> # {:ok, response} = HospitableClient.Reservations.get_reservation(
      iex> #   config,
      iex> #   "6f58fd0a-a9cb-3746-9219-384a156ff7bb",
      iex> #   include: "financials,guest,properties"
      iex> # )
      iex> config.api_key
      "api-key"

  """
  @spec get_reservation(config(), uuid(), get_reservation_opts()) ::
          {:ok, reservation_response()} | {:error, term()}
  def get_reservation(config, uuid, opts \\ []) do
    query_params = build_reservation_query(opts)
    base_path = "#{@base_url}/reservations/#{uuid}"
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
  Checks if a reservation status indicates the reservation is confirmed.

  ## Parameters
  - `reservation`: The reservation map

  ## Examples

      iex> reservation = %{reservation_status: %{current: %{category: "accepted"}}}
      iex> HospitableClient.Reservations.confirmed?(reservation)
      true

      iex> reservation = %{reservation_status: %{current: %{category: "request"}}}
      iex> HospitableClient.Reservations.confirmed?(reservation)
      false

  """
  @spec confirmed?(reservation()) :: boolean()
  def confirmed?(%{reservation_status: %{current: %{category: "accepted"}}}), do: true
  def confirmed?(_), do: false

  @doc """
  Checks if a reservation status indicates it needs action.

  ## Parameters
  - `reservation`: The reservation map

  ## Examples

      iex> reservation = %{reservation_status: %{current: %{category: "request"}}}
      iex> HospitableClient.Reservations.needs_action?(reservation)
      true

      iex> reservation = %{reservation_status: %{current: %{category: "accepted"}}}
      iex> HospitableClient.Reservations.needs_action?(reservation)
      false

  """
  @spec needs_action?(reservation()) :: boolean()
  def needs_action?(%{reservation_status: %{current: %{category: "request"}}}), do: true
  def needs_action?(%{reservation_status: %{current: %{category: "checkpoint"}}}), do: true
  def needs_action?(_), do: false

  @doc """
  Checks if a reservation was cancelled or not accepted.

  ## Parameters
  - `reservation`: The reservation map

  ## Examples

      iex> reservation = %{reservation_status: %{current: %{category: "cancelled"}}}
      iex> HospitableClient.Reservations.cancelled?(reservation)
      true

      iex> reservation = %{reservation_status: %{current: %{category: "not accepted"}}}
      iex> HospitableClient.Reservations.cancelled?(reservation)
      true

      iex> reservation = %{reservation_status: %{current: %{category: "accepted"}}}
      iex> HospitableClient.Reservations.cancelled?(reservation)
      false

  """
  @spec cancelled?(reservation()) :: boolean()
  def cancelled?(%{reservation_status: %{current: %{category: "cancelled"}}}), do: true
  def cancelled?(%{reservation_status: %{current: %{category: "not accepted"}}}), do: true
  def cancelled?(_), do: false

  @doc """
  Gets the detailed cancellation reason for non-accepted reservations.

  ## Parameters
  - `reservation`: The reservation map

  ## Examples

      iex> reservation = %{reservation_status: %{current: %{category: "not accepted", sub_category: "declined"}}}
      iex> HospitableClient.Reservations.cancellation_reason(reservation)
      "declined"

      iex> reservation = %{reservation_status: %{current: %{category: "accepted"}}}
      iex> HospitableClient.Reservations.cancellation_reason(reservation)
      nil

  """
  @spec cancellation_reason(reservation()) :: String.t() | nil
  def cancellation_reason(%{
        reservation_status: %{current: %{category: "not accepted", sub_category: reason}}
      }) do
    reason
  end

  def cancellation_reason(%{reservation_status: %{current: %{category: "cancelled"}}}), do: "cancelled"
  def cancellation_reason(_), do: nil

  @doc """
  Checks if a reservation status is unknown or unrecognized.

  ## Parameters
  - `reservation`: The reservation map

  ## Examples

      iex> reservation = %{reservation_status: %{current: %{category: "unknown"}}}
      iex> HospitableClient.Reservations.unknown_status?(reservation)
      true

      iex> reservation = %{reservation_status: %{current: %{category: "accepted"}}}
      iex> HospitableClient.Reservations.unknown_status?(reservation)
      false

  """
  @spec unknown_status?(reservation()) :: boolean()
  def unknown_status?(%{reservation_status: %{current: %{category: "unknown"}}}), do: true
  def unknown_status?(_), do: false

  # Private helper functions

  defp build_reservations_query(opts) do
    properties = Keyword.get(opts, :properties, [])
    other_params = Keyword.drop(opts, [:properties])

    properties_params =
      properties
      |> Enum.with_index()
      |> Enum.map(fn {prop, _index} -> "properties[]=#{URI.encode(prop)}" end)
      |> Enum.join("&")

    other_params_string =
      other_params
      |> Enum.filter(fn {_key, value} -> not is_nil(value) end)
      |> Enum.map(fn {key, value} -> "#{key}=#{URI.encode(to_string(value))}" end)
      |> Enum.join("&")

    case {properties_params, other_params_string} do
      {"", ""} -> ""
      {props, ""} -> props
      {"", others} -> others
      {props, others} -> "#{props}&#{others}"
    end
  end

  defp build_reservation_query(opts) do
    opts
    |> Enum.filter(fn {_key, value} -> not is_nil(value) end)
    |> Enum.map(fn {key, value} -> "#{key}=#{URI.encode(to_string(value))}" end)
    |> Enum.join("&")
  end
end