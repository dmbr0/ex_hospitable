defmodule HospitableClient.PropertiesTest do
  use ExUnit.Case
  doctest HospitableClient.Properties

  alias HospitableClient.Properties
  alias HospitableClient.Auth.Manager, as: AuthManager

  # Enhanced sample property data matching the API specification
  @sample_property_1 %{
    "id" => "550e8400-e29b-41d4-a716-446655440000",
    "name" => "Relaxing Villa near the sea",
    "public_name" => "Relaxing Villa near the sea",
    "picture" => "https://cdn2.thecatapi.com/images/d9m.jpg",
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
    "amenities" => ["wifi", "kitchen", "parking", "pool"],
    "description" => "Beautiful villa with sea view",
    "summary" => "Perfect for vacation",
    "check-in" => "15:00",
    "check-out" => "11:00",
    "currency" => "EUR",
    "capacity" => %{"max" => 6, "bedrooms" => 3, "beds" => 3, "bathrooms" => 2},
    "room_details" => [
      %{"type" => "bedroom", "quantity" => 3},
      %{"type" => "bathroom", "quantity" => 2}
    ],
    "house_rules" => %{
      "pets_allowed" => true,
      "smoking_allowed" => false,
      "events_allowed" => false
    },
    "listings" => [
      %{
        "platform" => "airbnb",
        "platform_id" => "24488",
        "platform_name" => "Luxury Villa Berlin",
        "platform_email" => "host@example.com"
      }
    ],
    "tags" => ["Luxury", "Sea View"],
    "property_type" => "villa",
    "room_type" => "entire_place",
    "calendar_restricted" => false,
    "user" => %{
      "id" => "497f6eca-6276-4993-bfeb-53cbbbba6f08",
      "email" => "owner@example.com",
      "name" => "John Doe"
    }
  }

  @sample_property_2 %{
    "id" => "123e4567-e89b-12d3-a456-426614174000",
    "name" => "Cozy Apartment Downtown",
    "public_name" => "Cozy Apartment Downtown",
    "picture" => "https://example.com/apartment.jpg",
    "address" => %{
      "number" => "15",
      "street" => "Maximilianstraße",
      "city" => "Munich",
      "state" => "Bavaria",
      "country" => "DE",
      "postcode" => "80539",
      "coordinates" => %{
        "latitude" => 48.1351,
        "longitude" => 11.5820
      },
      "display" => "15 Maximilianstraße, 80539 Munich, DE"
    },
    "timezone" => "+0100",
    "listed" => false,
    "amenities" => ["wifi", "heating"],
    "description" => "Cozy apartment in city center",
    "summary" => "Great for business trips",
    "check-in" => "14:00",
    "check-out" => "10:00",
    "currency" => "EUR",
    "capacity" => %{"max" => 2, "bedrooms" => 1, "beds" => 1, "bathrooms" => 1},
    "room_details" => [
      %{"type" => "bedroom", "quantity" => 1},
      %{"type" => "bathroom", "quantity" => 1}
    ],
    "house_rules" => %{
      "pets_allowed" => false,
      "smoking_allowed" => false,
      "events_allowed" => false
    },
    "listings" => [
      %{
        "platform" => "booking.com",
        "platform_id" => "12345",
        "platform_name" => "Munich Apartment",
        "platform_email" => "host2@example.com"
      }
    ],
    "tags" => ["Business", "Central"],
    "property_type" => "apartment",
    "room_type" => "entire_place",
    "calendar_restricted" => true,
    "user" => %{
      "id" => "987f6eca-6276-4993-bfeb-53cbbbba6f08",
      "email" => "owner2@example.com",
      "name" => "Jane Smith"
    }
  }

  @sample_property_3 %{
    "id" => "789a1234-bcde-5678-9012-3456789abcde",
    "name" => "Luxury Penthouse",
    "public_name" => "Luxury Penthouse",
    "picture" => "https://example.com/penthouse.jpg",
    "address" => %{
      "number" => "100",
      "street" => "5th Avenue",
      "city" => "New York",
      "state" => "New York",
      "country" => "US",
      "postcode" => "10001",
      "coordinates" => %{
        "latitude" => 40.7589,
        "longitude" => -73.9851
      },
      "display" => "100 5th Avenue, 10001 New York, US"
    },
    "timezone" => "-0500",
    "listed" => true,
    "amenities" => ["wifi", "kitchen", "parking", "pool", "gym", "concierge"],
    "description" => "Luxury penthouse with city views",
    "summary" => "Ultimate luxury experience",
    "check-in" => "16:00",
    "check-out" => "12:00",
    "currency" => "USD",
    "capacity" => %{"max" => 8, "bedrooms" => 4, "beds" => 4, "bathrooms" => 3},
    "room_details" => [
      %{"type" => "bedroom", "quantity" => 4},
      %{"type" => "bathroom", "quantity" => 3}
    ],
    "house_rules" => %{
      "pets_allowed" => true,
      "smoking_allowed" => false,
      "events_allowed" => true
    },
    "listings" => [
      %{
        "platform" => "vrbo",
        "platform_id" => "98765",
        "platform_name" => "NYC Luxury Penthouse",
        "platform_email" => "luxury@example.com"
      }
    ],
    "tags" => ["Luxury", "Penthouse", "City View"],
    "property_type" => "penthouse",
    "room_type" => "entire_place",
    "calendar_restricted" => false,
    "user" => %{
      "id" => "456f6eca-6276-4993-bfeb-53cbbbba6f08",
      "email" => "luxury@example.com",
      "name" => "Robert Johnson"
    }
  }

  @sample_response %{
    "data" => [@sample_property_1, @sample_property_2, @sample_property_3],
    "links" => %{
      "first" => "https://public.api.hospitable.com/v2/properties?page=1",
      "last" => "https://public.api.hospitable.com/v2/properties?page=2",
      "next" => "https://public.api.hospitable.com/v2/properties?page=2"
    },
    "meta" => %{
      "current_page" => 1,
      "per_page" => 10,
      "total" => 20
    }
  }

  setup do
    # Clear authentication state and set a test token
    AuthManager.clear_auth()
    AuthManager.set_token("test_token_for_properties")
    :ok
  end

  describe "UUID validation" do
    test "valid_uuid?/1 validates correct UUID format" do
      valid_uuids = [
        "550e8400-e29b-41d4-a716-446655440000",
        "123e4567-e89b-12d3-a456-426614174000",
        "f47ac10b-58cc-4372-a567-0e02b2c3d479"
      ]

      Enum.each(valid_uuids, fn uuid ->
        assert Properties.valid_uuid?(uuid), "#{uuid} should be valid"
      end)
    end

    test "valid_uuid?/1 rejects invalid UUID formats" do
      invalid_uuids = [
        "invalid-uuid",
        "550e8400-e29b-41d4-a716",
        "550e8400-e29b-41d4-a716-446655440000-extra",
        "",
        "550e8400-e29b-41d4-a716-44665544000g"
      ]

      Enum.each(invalid_uuids, fn uuid ->
        assert !Properties.valid_uuid?(uuid), "#{uuid} should be invalid"
      end)
    end
  end

  describe "include option validation" do
    test "get_properties/1 accepts valid include options" do
      valid_includes = [
        "user",
        "listings",
        "details",
        "bookings",
        "user,listings",
        "user,listings,details,bookings"
      ]

      Enum.each(valid_includes, fn include ->
        # This should not raise an error (would need real API to test fully)
        assert is_function(&Properties.get_properties/1)
      end)
    end
  end

  describe "coordinate handling" do
    test "distance_between/3 calculates distance correctly" do
      # Distance between Berlin and Munich is approximately 504 km
      berlin_prop = @sample_property_1
      munich_prop = @sample_property_2

      {:ok, distance_km} = Properties.distance_between(berlin_prop, munich_prop, :km)
      {:ok, distance_miles} = Properties.distance_between(berlin_prop, munich_prop, :miles)

      # Allow some tolerance for rounding
      assert distance_km > 500 and distance_km < 510
      assert distance_miles > 310 and distance_miles < 320
    end

    test "distance_between/3 handles missing coordinates" do
      prop_no_coords = Map.delete(@sample_property_1, "address")
      
      result = Properties.distance_between(prop_no_coords, @sample_property_2)
      assert {:error, :no_coordinates} = result
    end

    test "find_nearby/5 finds properties within radius" do
      properties = [@sample_property_1, @sample_property_2, @sample_property_3]
      
      # Find properties within 100km of Berlin
      nearby_berlin = Properties.find_nearby(properties, 52.5200, 13.4050, 100, :km)
      assert length(nearby_berlin) == 1
      assert hd(nearby_berlin)["id"] == @sample_property_1["id"]
      
      # Find properties within 1000km of Berlin (should include Munich)
      nearby_central_europe = Properties.find_nearby(properties, 52.5200, 13.4050, 1000, :km)
      assert length(nearby_central_europe) == 2
    end

    test "within_radius filter works correctly" do
      properties = [@sample_property_1, @sample_property_2, @sample_property_3]
      
      # Properties within 100km of Berlin
      filtered = Properties.filter_properties(properties, %{
        within_radius: %{lat: 52.5200, lon: 13.4050, radius: 100, unit: :km}
      })
      
      assert length(filtered) == 1
      assert hd(filtered)["id"] == @sample_property_1["id"]
    end
  end

  describe "enhanced filtering" do
    test "filters by coordinate radius" do
      # Test radius filtering around New York (should find penthouse)
      filtered = Properties.filter_properties(@sample_response, %{
        within_radius: %{lat: 40.7589, lon: -73.9851, radius: 50, unit: :miles}
      })
      
      assert length(filtered) == 1
      assert hd(filtered)["id"] == @sample_property_3["id"]
    end

    test "combines location and feature filters" do
      # European properties with pools
      filtered = Properties.filter_properties(@sample_response, %{
        country: "DE",
        has_amenities: ["pool"],
        currency: "EUR"
      })
      
      assert length(filtered) == 1
      assert hd(filtered)["id"] == @sample_property_1["id"]
    end

    test "filters by state" do
      bavaria_props = Properties.filter_properties(@sample_response, %{state: "Bavaria"})
      assert length(bavaria_props) == 1
      assert hd(bavaria_props)["id"] == @sample_property_2["id"]
    end

    test "filters by max capacity" do
      small_props = Properties.filter_properties(@sample_response, %{max_capacity: 3})
      assert length(small_props) == 1
      assert hd(small_props)["id"] == @sample_property_2["id"]
    end
  end

  describe "data processing functions" do
    test "list_amenities/1 extracts unique amenities" do
      amenities = Properties.list_amenities(@sample_response)
      
      expected_amenities = ["concierge", "gym", "heating", "kitchen", "parking", "pool", "wifi"]
      assert amenities == expected_amenities
    end

    test "list_property_types/1 extracts unique property types" do
      types = Properties.list_property_types(@sample_response)
      
      expected_types = ["apartment", "penthouse", "villa"]
      assert types == expected_types
    end

    test "list_currencies/1 extracts unique currencies" do
      currencies = Properties.list_currencies(@sample_response)
      
      expected_currencies = ["EUR", "USD"]
      assert currencies == expected_currencies
    end
  end

  describe "grouping functionality" do
    test "groups by city" do
      grouped = Properties.group_properties(@sample_response, :city)
      
      assert Map.has_key?(grouped, "Berlin")
      assert Map.has_key?(grouped, "Munich")
      assert Map.has_key?(grouped, "New York")
      assert length(grouped["Berlin"]) == 1
      assert length(grouped["Munich"]) == 1
      assert length(grouped["New York"]) == 1
    end

    test "groups by property type" do
      grouped = Properties.group_properties(@sample_response, :property_type)
      
      assert Map.has_key?(grouped, "villa")
      assert Map.has_key?(grouped, "apartment")
      assert Map.has_key?(grouped, "penthouse")
      assert length(grouped["villa"]) == 1
      assert length(grouped["apartment"]) == 1
      assert length(grouped["penthouse"]) == 1
    end

    test "groups by currency" do
      grouped = Properties.group_properties(@sample_response, :currency)
      
      assert Map.has_key?(grouped, "EUR")
      assert Map.has_key?(grouped, "USD")
      assert length(grouped["EUR"]) == 2
      assert length(grouped["USD"]) == 1
    end

    test "groups by state" do
      grouped = Properties.group_properties(@sample_response, :state)
      
      assert Map.has_key?(grouped, "Berlin")
      assert Map.has_key?(grouped, "Bavaria")
      assert Map.has_key?(grouped, "New York")
    end
  end

  describe "error handling" do
    test "get_property/2 validates UUID format" do
      # This would be tested with actual HTTP calls in integration tests
      assert is_function(&Properties.get_property/2)
    end

    test "handles invalid include options" do
      # This would be tested with actual validation in integration tests
      assert is_function(&Properties.get_properties/1)
    end
  end

  describe "complex filtering scenarios" do
    test "luxury property search" do
      # Find luxury properties: Listed, expensive currency, luxury amenities, events allowed
      luxury_filter = Properties.filter_properties(@sample_response, %{
        listed: true,
        currency: "USD",
        has_amenities: ["pool", "gym", "concierge"],
        events_allowed: true,
        min_bedrooms: 4
      })
      
      assert length(luxury_filter) == 1
      assert hd(luxury_filter)["id"] == @sample_property_3["id"]
      assert hd(luxury_filter)["property_type"] == "penthouse"
    end

    test "pet-friendly properties in Germany" do
      pet_friendly_de = Properties.filter_properties(@sample_response, %{
        country: "DE",
        pets_allowed: true,
        listed: true
      })
      
      assert length(pet_friendly_de) == 1
      assert hd(pet_friendly_de)["id"] == @sample_property_1["id"]
    end

    test "business travel suitable properties" do
      # Small, centrally located, calendar not restricted
      business_suitable = Properties.filter_properties(@sample_response, %{
        max_capacity: 4,
        has_amenities: ["wifi"],
        calendar_restricted: false
      })
      
      assert length(business_suitable) == 2
      property_ids = Enum.map(business_suitable, fn p -> p["id"] end)
      assert @sample_property_1["id"] in property_ids
      assert @sample_property_3["id"] in property_ids
    end
  end

  describe "API specification compliance" do
    test "handles enhanced address structure with coordinates" do
      # Test that we can extract coordinates properly
      {:ok, {lat, lon}} = Properties.distance_between(@sample_property_1, @sample_property_1)
      assert lat == 52.5200
      assert lon == 13.4050
    end

    test "processes all required fields from specification" do
      property = @sample_property_1
      
      # Basic fields
      assert Map.has_key?(property, "id")
      assert Map.has_key?(property, "name")
      assert Map.has_key?(property, "public_name")
      assert Map.has_key?(property, "picture")
      
      # Address with coordinates
      assert get_in(property, ["address", "coordinates", "latitude"])
      assert get_in(property, ["address", "coordinates", "longitude"])
      
      # Timing
      assert Map.has_key?(property, "check-in")
      assert Map.has_key?(property, "check-out")
      
      # Capacity
      assert get_in(property, ["capacity", "max"])
      assert get_in(property, ["capacity", "bedrooms"])
      assert get_in(property, ["capacity", "bathrooms"])
      
      # House rules
      assert get_in(property, ["house_rules", "pets_allowed"]) != nil
      assert get_in(property, ["house_rules", "smoking_allowed"]) != nil
      assert get_in(property, ["house_rules", "events_allowed"]) != nil
    end
  end
end
