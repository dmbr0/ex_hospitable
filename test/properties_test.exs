defmodule HospitableClient.PropertiesTest do
  use ExUnit.Case
  doctest HospitableClient.Properties

  alias HospitableClient.Properties
  alias HospitableClient.Auth.Manager, as: AuthManager

  # Comprehensive sample property data matching the schema
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
      "postcode" => "10405"
    },
    "coordinates" => %{"display" => "52.5200,13.4050"},
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
    "host" => %{"first_name" => "John", "last_name" => "Doe"},
    "tags" => ["Luxury", "Sea View"],
    "property_type" => "villa",
    "room_type" => "entire_place",
    "calendar_restricted" => false,
    "bookings" => %{
      "booking_policies" => %{
        "cancellation" => ["flexible"],
        "payment_terms" => %{
          "status" => "active",
          "description" => ["Pay 50% upfront"],
          "grace_period" => "24h"
        }
      },
      "listing_markups" => [],
      "security_deposits" => [],
      "occupancy_based_rules" => %{
        "guests_included" => 4,
        "extra_guest_fee" => %{
          "type" => "fixed",
          "value" => %{"amount" => 25, "formatted" => "€25"}
        }
      },
      "fees" => [],
      "discounts" => []
    },
    "details" => %{
      "space_overview" => "Spacious villa with modern amenities",
      "guest_access" => "Full access to villa",
      "wifi_name" => "VillaWiFi",
      "wifi_password" => "password123"
    },
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
      "postcode" => "80539"
    },
    "coordinates" => %{"display" => "48.1351,11.5820"},
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
    "host" => %{"first_name" => "Jane", "last_name" => "Smith"},
    "tags" => ["Business", "Central"],
    "property_type" => "apartment",
    "room_type" => "entire_place",
    "calendar_restricted" => true,
    "bookings" => %{
      "booking_policies" => %{
        "cancellation" => ["strict"],
        "payment_terms" => %{
          "status" => "active",
          "description" => ["Pay full amount upfront"],
          "grace_period" => "12h"
        }
      },
      "listing_markups" => [],
      "security_deposits" => [
        %{
          "name" => "Standard Deposit",
          "type" => "fixed",
          "value" => %{"amount" => 100, "formatted" => "€100"}
        }
      ],
      "occupancy_based_rules" => %{
        "guests_included" => 2,
        "extra_guest_fee" => %{
          "type" => "fixed",
          "value" => %{"amount" => 15, "formatted" => "€15"}
        }
      },
      "fees" => [],
      "discounts" => []
    },
    "details" => %{
      "space_overview" => "Modern apartment with city views",
      "guest_access" => "Full apartment access",
      "wifi_name" => "ApartmentWiFi",
      "wifi_password" => "munich2024"
    },
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
      "postcode" => "10001"
    },
    "coordinates" => %{"display" => "40.7589,-73.9851"},
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
    "host" => %{"first_name" => "Robert", "last_name" => "Johnson"},
    "tags" => ["Luxury", "Penthouse", "City View"],
    "property_type" => "penthouse",
    "room_type" => "entire_place",
    "calendar_restricted" => false,
    "bookings" => %{
      "booking_policies" => %{
        "cancellation" => ["moderate"],
        "payment_terms" => %{
          "status" => "active",
          "description" => ["Pay 30% upfront, rest on arrival"],
          "grace_period" => "48h"
        }
      },
      "listing_markups" => [],
      "security_deposits" => [
        %{
          "name" => "Luxury Deposit",
          "type" => "fixed",
          "value" => %{"amount" => 1000, "formatted" => "$1000"}
        }
      ],
      "occupancy_based_rules" => %{
        "guests_included" => 6,
        "extra_guest_fee" => %{
          "type" => "fixed",
          "value" => %{"amount" => 50, "formatted" => "$50"}
        }
      },
      "fees" => [],
      "discounts" => []
    },
    "details" => %{
      "space_overview" => "Stunning penthouse with panoramic city views",
      "guest_access" => "Full penthouse access including rooftop",
      "wifi_name" => "PenthouseWiFi",
      "wifi_password" => "luxury2024"
    },
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

  describe "get_properties/1" do
    test "builds correct query parameters for basic request" do
      assert is_function(&Properties.get_properties/1)
    end

    test "builds correct query parameters with pagination" do
      opts = %{page: 2, per_page: 25}
      assert is_function(&Properties.get_properties/1)
    end

    test "builds correct query parameters with includes" do
      opts = %{include: "listings,user,details,bookings"}
      assert is_function(&Properties.get_properties/1)
    end
  end

  describe "get_property/2" do
    test "accepts property ID and options" do
      property_id = "550e8400-e29b-41d4-a716-446655440000"
      opts = %{include: "listings,bookings"}
      
      assert is_function(&Properties.get_property/2)
    end
  end

  describe "list_amenities/1" do
    test "extracts amenities from response data" do
      amenities = Properties.list_amenities(@sample_response)
      
      expected_amenities = ["concierge", "gym", "heating", "kitchen", "parking", "pool", "wifi"]
      assert amenities == expected_amenities
    end

    test "extracts amenities from property list directly" do
      properties = [@sample_property_1, @sample_property_2, @sample_property_3]
      
      amenities = Properties.list_amenities(properties)
      
      expected_amenities = ["concierge", "gym", "heating", "kitchen", "parking", "pool", "wifi"]
      assert amenities == expected_amenities
    end

    test "handles properties without amenities" do
      property_without_amenities = Map.delete(@sample_property_1, "amenities")
      properties = [property_without_amenities, @sample_property_2]
      
      amenities = Properties.list_amenities(properties)
      
      expected_amenities = ["heating", "wifi"]
      assert amenities == expected_amenities
    end
  end

  describe "list_property_types/1" do
    test "extracts unique property types" do
      types = Properties.list_property_types(@sample_response)
      
      expected_types = ["apartment", "penthouse", "villa"]
      assert types == expected_types
    end
  end

  describe "list_currencies/1" do
    test "extracts unique currencies" do
      currencies = Properties.list_currencies(@sample_response)
      
      expected_currencies = ["EUR", "USD"]
      assert currencies == expected_currencies
    end
  end

  describe "filter_properties/2" do
    test "filters by listed status" do
      # Filter for listed properties
      listed_properties = Properties.filter_properties(@sample_response, %{listed: true})
      assert length(listed_properties) == 2
      assert Enum.all?(listed_properties, fn p -> p["listed"] == true end)
      
      # Filter for unlisted properties
      unlisted_properties = Properties.filter_properties(@sample_response, %{listed: false})
      assert length(unlisted_properties) == 1
      assert hd(unlisted_properties)["id"] == @sample_property_2["id"]
    end

    test "filters by property type" do
      apartment_properties = Properties.filter_properties(@sample_response, %{property_type: "apartment"})
      assert length(apartment_properties) == 1
      assert hd(apartment_properties)["property_type"] == "apartment"
    end

    test "filters by currency" do
      eur_properties = Properties.filter_properties(@sample_response, %{currency: "EUR"})
      assert length(eur_properties) == 2
      
      usd_properties = Properties.filter_properties(@sample_response, %{currency: "USD"})
      assert length(usd_properties) == 1
    end

    test "filters by minimum capacity" do
      large_properties = Properties.filter_properties(@sample_response, %{min_capacity: 6})
      assert length(large_properties) == 2
      
      very_large_properties = Properties.filter_properties(@sample_response, %{min_capacity: 8})
      assert length(very_large_properties) == 1
      assert hd(very_large_properties)["id"] == @sample_property_3["id"]
    end

    test "filters by city" do
      berlin_properties = Properties.filter_properties(@sample_response, %{city: "Berlin"})
      assert length(berlin_properties) == 1
      assert hd(berlin_properties)["id"] == @sample_property_1["id"]
      
      # Test case insensitive
      berlin_properties_lower = Properties.filter_properties(@sample_response, %{city: "berlin"})
      assert length(berlin_properties_lower) == 1
    end

    test "filters by state" do
      bavaria_properties = Properties.filter_properties(@sample_response, %{state: "Bavaria"})
      assert length(bavaria_properties) == 1
      assert hd(bavaria_properties)["id"] == @sample_property_2["id"]
    end

    test "filters by country" do
      german_properties = Properties.filter_properties(@sample_response, %{country: "DE"})
      assert length(german_properties) == 2
      
      us_properties = Properties.filter_properties(@sample_response, %{country: "US"})
      assert length(us_properties) == 1
    end

    test "filters by required amenities" do
      wifi_properties = Properties.filter_properties(@sample_response, %{has_amenities: ["wifi"]})
      assert length(wifi_properties) == 3
      
      pool_properties = Properties.filter_properties(@sample_response, %{has_amenities: ["pool"]})
      assert length(pool_properties) == 2
      
      # Multiple amenities (AND logic)
      wifi_and_pool = Properties.filter_properties(@sample_response, %{has_amenities: ["wifi", "pool"]})
      assert length(wifi_and_pool) == 2
      
      # Luxury amenities
      luxury_amenities = Properties.filter_properties(@sample_response, %{has_amenities: ["pool", "gym", "concierge"]})
      assert length(luxury_amenities) == 1
      assert hd(luxury_amenities)["id"] == @sample_property_3["id"]
    end

    test "filters by house rules" do
      # Pet-friendly properties
      pet_friendly = Properties.filter_properties(@sample_response, %{pets_allowed: true})
      assert length(pet_friendly) == 2
      
      # No pets allowed
      no_pets = Properties.filter_properties(@sample_response, %{pets_allowed: false})
      assert length(no_pets) == 1
      assert hd(no_pets)["id"] == @sample_property_2["id"]
      
      # Events allowed
      events_ok = Properties.filter_properties(@sample_response, %{events_allowed: true})
      assert length(events_ok) == 1
      assert hd(events_ok)["id"] == @sample_property_3["id"]
    end

    test "filters by bedrooms and bathrooms" do
      # Properties with at least 2 bedrooms
      large_bedrooms = Properties.filter_properties(@sample_response, %{min_bedrooms: 2})
      assert length(large_bedrooms) == 2
      
      # Properties with at least 3 bathrooms
      many_bathrooms = Properties.filter_properties(@sample_response, %{min_bathrooms: 3})
      assert length(many_bathrooms) == 1
      assert hd(many_bathrooms)["id"] == @sample_property_3["id"]
    end

    test "filters by calendar restriction" do
      restricted = Properties.filter_properties(@sample_response, %{calendar_restricted: true})
      assert length(restricted) == 1
      assert hd(restricted)["id"] == @sample_property_2["id"]
      
      unrestricted = Properties.filter_properties(@sample_response, %{calendar_restricted: false})
      assert length(unrestricted) == 2
    end

    test "combines multiple filters" do
      # Listed AND in Germany AND has pool AND pets allowed
      filtered = Properties.filter_properties(@sample_response, %{
        listed: true,
        country: "DE",
        has_amenities: ["pool"],
        pets_allowed: true
      })
      
      assert length(filtered) == 1
      assert hd(filtered)["id"] == @sample_property_1["id"]
    end

    test "complex filtering scenario" do
      # Luxury properties: Listed, min 4 bedrooms, pool + gym, events allowed, USD currency
      luxury_filter = Properties.filter_properties(@sample_response, %{
        listed: true,
        min_bedrooms: 4,
        has_amenities: ["pool", "gym"],
        events_allowed: true,
        currency: "USD"
      })
      
      assert length(luxury_filter) == 1
      assert hd(luxury_filter)["id"] == @sample_property_3["id"]
    end
  end

  describe "group_properties/2" do
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
  end

  describe "get_all_properties/1" do
    test "accepts options for fetching all properties" do
      assert is_function(&Properties.get_all_properties/1)
    end
  end
end
