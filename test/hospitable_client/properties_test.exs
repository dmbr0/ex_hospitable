defmodule HospitableClient.PropertiesTest do
  use ExUnit.Case
  doctest HospitableClient.Properties

  alias HospitableClient.Properties

  setup do
    config = HospitableClient.new("test-api-key")
    {:ok, config: config}
  end

  describe "get_properties/2" do
    test "accepts optional parameters", %{config: config} do
      # This will return an error due to invalid API key, but validates parameter handling
      result = Properties.get_properties(config)
      assert {:error, _} = result
    end

    test "accepts include parameters", %{config: config} do
      opts = [include: "user,listings,details,bookings"]
      result = Properties.get_properties(config, opts)
      assert {:error, _} = result
    end

    test "accepts pagination parameters", %{config: config} do
      opts = [page: 1, per_page: 50]
      result = Properties.get_properties(config, opts)
      assert {:error, _} = result
    end

    test "handles combined parameters", %{config: config} do
      opts = [
        include: "user,listings,details",
        page: 2,
        per_page: 25
      ]

      result = Properties.get_properties(config, opts)
      assert {:error, _} = result
    end
  end

  describe "search_properties/2" do
    test "requires adults parameter", %{config: config} do
      assert_raise ArgumentError, "adults parameter is required for property search", fn ->
        Properties.search_properties(config, start_date: "2024-08-16", end_date: "2024-08-21")
      end
    end

    test "requires start_date parameter", %{config: config} do
      assert_raise ArgumentError, "start_date parameter is required for property search", fn ->
        Properties.search_properties(config, adults: 2, end_date: "2024-08-21")
      end
    end

    test "requires end_date parameter", %{config: config} do
      assert_raise ArgumentError, "end_date parameter is required for property search", fn ->
        Properties.search_properties(config, adults: 2, start_date: "2024-08-16")
      end
    end

    test "validates date format", %{config: config} do
      assert_raise ArgumentError, "invalid date format, use YYYY-MM-DD", fn ->
        Properties.search_properties(config,
          adults: 2,
          start_date: "invalid-date",
          end_date: "2024-08-21"
        )
      end
    end

    test "validates start_date is not in the past", %{config: config} do
      yesterday = Date.utc_today() |> Date.add(-1) |> Date.to_string()

      assert_raise ArgumentError, "start_date cannot be in the past", fn ->
        Properties.search_properties(config,
          adults: 2,
          start_date: yesterday,
          end_date: "2024-12-31"
        )
      end
    end

    test "validates end_date is after start_date", %{config: config} do
      future_date = Date.utc_today() |> Date.add(10) |> Date.to_string()
      earlier_date = Date.utc_today() |> Date.add(5) |> Date.to_string()

      assert_raise ArgumentError, "end_date must be after start_date", fn ->
        Properties.search_properties(config,
          adults: 2,
          start_date: future_date,
          end_date: earlier_date
        )
      end
    end

    test "validates search period does not exceed 90 days", %{config: config} do
      start_date = Date.utc_today() |> Date.add(1) |> Date.to_string()
      end_date = Date.utc_today() |> Date.add(92) |> Date.to_string()

      assert_raise ArgumentError, "search period cannot exceed 90 days", fn ->
        Properties.search_properties(config,
          adults: 2,
          start_date: start_date,
          end_date: end_date
        )
      end
    end

    test "validates start_date is not more than 3 years in the future", %{config: config} do
      far_future = Date.utc_today() |> Date.add(365 * 3 + 1) |> Date.to_string()
      far_future_end = Date.utc_today() |> Date.add(365 * 3 + 5) |> Date.to_string()

      assert_raise ArgumentError, "start_date cannot be more than 3 years in the future", fn ->
        Properties.search_properties(config,
          adults: 2,
          start_date: far_future,
          end_date: far_future_end
        )
      end
    end

    test "accepts valid required parameters", %{config: config} do
      start_date = Date.utc_today() |> Date.add(1) |> Date.to_string()
      end_date = Date.utc_today() |> Date.add(5) |> Date.to_string()

      opts = [
        adults: 2,
        start_date: start_date,
        end_date: end_date
      ]

      result = Properties.search_properties(config, opts)
      assert {:error, _} = result
    end

    test "accepts optional parameters", %{config: config} do
      start_date = Date.utc_today() |> Date.add(1) |> Date.to_string()
      end_date = Date.utc_today() |> Date.add(5) |> Date.to_string()

      opts = [
        adults: 2,
        children: 1,
        infants: 0,
        pets: 1,
        start_date: start_date,
        end_date: end_date,
        include: "listings,details"
      ]

      result = Properties.search_properties(config, opts)
      assert {:error, _} = result
    end

    test "accepts location parameter", %{config: config} do
      start_date = Date.utc_today() |> Date.add(1) |> Date.to_string()
      end_date = Date.utc_today() |> Date.add(5) |> Date.to_string()

      opts = [
        adults: 2,
        start_date: start_date,
        end_date: end_date,
        location: %{latitude: 52.520008, longitude: 13.404954}
      ]

      result = Properties.search_properties(config, opts)
      assert {:error, _} = result
    end
  end

  describe "property helper functions" do
    test "pet_friendly?/1 identifies pet-friendly properties" do
      pet_friendly = %{house_rules: %{pets_allowed: true}}
      not_pet_friendly = %{house_rules: %{pets_allowed: false}}
      no_rules = %{}

      assert Properties.pet_friendly?(pet_friendly) == true
      assert Properties.pet_friendly?(not_pet_friendly) == false
      assert Properties.pet_friendly?(no_rules) == false
    end

    test "smoking_allowed?/1 identifies smoking-allowed properties" do
      smoking_allowed = %{house_rules: %{smoking_allowed: true}}
      no_smoking = %{house_rules: %{smoking_allowed: false}}
      no_rules = %{}

      assert Properties.smoking_allowed?(smoking_allowed) == true
      assert Properties.smoking_allowed?(no_smoking) == false
      assert Properties.smoking_allowed?(no_rules) == false
    end

    test "events_allowed?/1 identifies event-allowed properties" do
      events_allowed = %{house_rules: %{events_allowed: true}}
      no_events = %{house_rules: %{events_allowed: false}}
      events_unknown = %{house_rules: %{events_allowed: nil}}
      no_rules = %{}

      assert Properties.events_allowed?(events_allowed) == true
      assert Properties.events_allowed?(no_events) == false
      assert Properties.events_allowed?(events_unknown) == false
      assert Properties.events_allowed?(no_rules) == false
    end

    test "listed?/1 identifies listed properties" do
      listed_property = %{listed: true}
      unlisted_property = %{listed: false}
      no_listing_info = %{}

      assert Properties.listed?(listed_property) == true
      assert Properties.listed?(unlisted_property) == false
      assert Properties.listed?(no_listing_info) == false
    end

    test "max_guests/1 returns maximum guest capacity" do
      property_with_capacity = %{capacity: %{max: 6}}
      property_without_capacity = %{}

      assert Properties.max_guests(property_with_capacity) == 6
      assert Properties.max_guests(property_without_capacity) == 0
    end

    test "available?/1 checks search result availability" do
      available_result = %{availability: %{available: true}}
      unavailable_result = %{availability: %{available: false}}
      no_availability_info = %{}

      assert Properties.available?(available_result) == true
      assert Properties.available?(unavailable_result) == false
      assert Properties.available?(no_availability_info) == false
    end

    test "unavailability_reasons/1 returns unavailability reasons" do
      unavailable_result = %{
        availability: %{
          details: [
            %{notAvailableReason: "booked", date: "2024-08-16"},
            %{notAvailableReason: "blocked", date: "2024-08-17"}
          ]
        }
      }

      no_details = %{availability: %{details: []}}
      no_availability = %{}

      assert Properties.unavailability_reasons(unavailable_result) == ["booked", "blocked"]
      assert Properties.unavailability_reasons(no_details) == []
      assert Properties.unavailability_reasons(no_availability) == []
    end
  end

  describe "complex property scenarios" do
    test "handles complete property with all fields" do
      complete_property = %{
        id: "prop-uuid",
        name: "Test Property",
        public_name: "Beautiful Test Property",
        picture: "https://example.com/pic.jpg",
        address: %{
          number: "123",
          street: "Main Street",
          city: "Test City",
          state: "Test State",
          country: "Test Country",
          postcode: "12345",
          coordinates: %{latitude: 40.7128, longitude: -74.0060},
          display: "123 Main Street, Test City"
        },
        timezone: "America/New_York",
        listed: true,
        amenities: ["wifi", "kitchen", "parking"],
        description: "A beautiful test property",
        summary: "Perfect for testing",
        check_in: "15:00",
        check_out: "11:00",
        currency: "USD",
        capacity: %{max: 4, bedrooms: 2, beds: 2, bathrooms: 1},
        room_details: [%{type: "bedroom", quantity: 2}],
        house_rules: %{
          pets_allowed: true,
          smoking_allowed: false,
          events_allowed: nil
        },
        listings: [
          %{
            platform: "airbnb",
            platform_id: "12345",
            platform_name: "Test Listing",
            platform_email: "host@example.com"
          }
        ],
        ical_imports: [],
        tags: ["family-friendly", "downtown"],
        property_type: "apartment",
        room_type: "entire_place",
        calendar_restricted: false,
        parent_child: nil,
        user: %{
          id: "user-uuid",
          email: "owner@example.com",
          name: "Test Owner"
        }
      }

      # Test all helper functions work with complete property
      assert Properties.pet_friendly?(complete_property) == true
      assert Properties.smoking_allowed?(complete_property) == false
      assert Properties.events_allowed?(complete_property) == false
      assert Properties.listed?(complete_property) == true
      assert Properties.max_guests(complete_property) == 4
    end

    test "handles search result with pricing and availability" do
      search_result = %{
        property: %{
          id: "prop-uuid",
          name: "Search Result Property",
          capacity: %{max: 2}
        },
        pricing: %{
          daily: [
            %{
              date: "2024-08-16",
              price: %{
                currency: "USD",
                amount: 15000,
                formatted_string: "$150.00",
                formatted_decimal: "150.00"
              }
            }
          ],
          total_without_taxes: %{
            currency: "USD",
            amount: 75000,
            formatted_string: "$750.00",
            formatted_decimal: "750.00"
          }
        },
        availability: %{
          available: true,
          details: []
        },
        distance_in_km: 2.5
      }

      assert Properties.available?(search_result) == true
      assert Properties.unavailability_reasons(search_result) == []
      assert Properties.max_guests(search_result.property) == 2
    end
  end

  describe "query building" do
    test "builds valid query parameters for get_properties" do
      # Test that valid parameters don't cause errors
      opts = [include: "user,listings", page: 1, per_page: 50]
      config = HospitableClient.new("test-key")

      # Should not raise any errors with valid parameters
      result = Properties.get_properties(config, opts)
      assert {:error, _} = result
    end

    test "builds valid query parameters for search_properties" do
      start_date = Date.utc_today() |> Date.add(1) |> Date.to_string()
      end_date = Date.utc_today() |> Date.add(5) |> Date.to_string()

      opts = [
        adults: 2,
        children: 1,
        pets: 1,
        start_date: start_date,
        end_date: end_date,
        include: "listings,details",
        location: %{latitude: 52.5, longitude: 13.4}
      ]

      config = HospitableClient.new("test-key")

      # Should not raise any errors with valid parameters
      result = Properties.search_properties(config, opts)
      assert {:error, _} = result
    end
  end

  describe "edge cases" do
    test "handles empty property maps gracefully" do
      empty_property = %{}

      assert Properties.pet_friendly?(empty_property) == false
      assert Properties.smoking_allowed?(empty_property) == false
      assert Properties.events_allowed?(empty_property) == false
      assert Properties.listed?(empty_property) == false
      assert Properties.max_guests(empty_property) == 0
    end

    test "handles search results without availability info" do
      minimal_search_result = %{property: %{}}

      assert Properties.available?(minimal_search_result) == false
      assert Properties.unavailability_reasons(minimal_search_result) == []
    end

    test "validates boundary dates correctly" do
      config = HospitableClient.new("test-key")

      # Exactly 90 days should be valid
      start_date = Date.utc_today() |> Date.add(1) |> Date.to_string()
      end_date = Date.utc_today() |> Date.add(91) |> Date.to_string()

      opts = [adults: 2, start_date: start_date, end_date: end_date]
      result = Properties.search_properties(config, opts)
      assert {:error, _} = result  # Should not raise ArgumentError

      # Exactly at 3 years should be valid
      three_years_future = Date.utc_today() |> Date.add(365 * 3) |> Date.to_string()
      three_years_future_end = Date.utc_today() |> Date.add(365 * 3 + 5) |> Date.to_string()

      opts = [adults: 2, start_date: three_years_future, end_date: three_years_future_end]
      result = Properties.search_properties(config, opts)
      assert {:error, _} = result  # Should not raise ArgumentError
    end
  end
end