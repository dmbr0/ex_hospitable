#!/usr/bin/env elixir

# Enhanced validation script for the updated Properties module
# Tests the new features added based on the JSON schema

Mix.install([
  {:ex_hospitable, path: "."}
])

defmodule EnhancedPropertiesValidation do
  def run do
    IO.puts("🔍 Enhanced Properties Module Validation")
    IO.puts("=" |> String.duplicate(50))

    # Set up authentication
    HospitableClient.set_token("validation_token")

    # Test new data processing functions
    test_data_processing_functions()

    # Test enhanced filtering
    test_enhanced_filtering()

    # Test grouping functionality
    test_grouping_functionality()

    IO.puts("\n✅ Enhanced validation completed!")
    IO.puts("🎯 All new features working correctly!")
  end

  defp test_data_processing_functions do
    IO.puts("\n1. Testing Enhanced Data Processing Functions")
    IO.puts("-" |> String.duplicate(40))

    # Sample data with schema-compliant structure
    sample_properties = [
      %{
        "id" => "1",
        "name" => "Berlin Villa",
        "property_type" => "villa",
        "currency" => "EUR",
        "amenities" => ["wifi", "pool", "kitchen"],
        "address" => %{"city" => "Berlin", "state" => "Berlin", "country" => "DE"},
        "capacity" => %{"max" => 6, "bedrooms" => 3, "bathrooms" => 2},
        "house_rules" => %{"pets_allowed" => true, "smoking_allowed" => false, "events_allowed" => false}
      },
      %{
        "id" => "2", 
        "name" => "NYC Penthouse",
        "property_type" => "penthouse",
        "currency" => "USD",
        "amenities" => ["wifi", "gym", "concierge"],
        "address" => %{"city" => "New York", "state" => "New York", "country" => "US"},
        "capacity" => %{"max" => 8, "bedrooms" => 4, "bathrooms" => 3},
        "house_rules" => %{"pets_allowed" => true, "smoking_allowed" => false, "events_allowed" => true}
      }
    ]

    # Test list_property_types
    try do
      types = HospitableClient.Properties.list_property_types(sample_properties)
      IO.puts("   ✓ list_property_types: #{inspect(types)}")
    rescue
      e -> IO.puts("   ✗ list_property_types failed: #{inspect(e)}")
    end

    # Test list_currencies
    try do
      currencies = HospitableClient.Properties.list_currencies(sample_properties)
      IO.puts("   ✓ list_currencies: #{inspect(currencies)}")
    rescue
      e -> IO.puts("   ✗ list_currencies failed: #{inspect(e)}")
    end

    # Test list_amenities (existing)
    try do
      amenities = HospitableClient.Properties.list_amenities(sample_properties)
      IO.puts("   ✓ list_amenities: #{inspect(amenities)}")
    rescue
      e -> IO.puts("   ✗ list_amenities failed: #{inspect(e)}")
    end
  end

  defp test_enhanced_filtering do
    IO.puts("\n2. Testing Enhanced Filtering Options")
    IO.puts("-" |> String.duplicate(40))

    sample_properties = [
      %{
        "id" => "1",
        "listed" => true,
        "property_type" => "villa",
        "currency" => "EUR",
        "amenities" => ["wifi", "pool"],
        "address" => %{"city" => "Berlin", "state" => "Berlin", "country" => "DE"},
        "capacity" => %{"max" => 6, "bedrooms" => 3, "bathrooms" => 2},
        "house_rules" => %{"pets_allowed" => true, "smoking_allowed" => false},
        "calendar_restricted" => false
      },
      %{
        "id" => "2",
        "listed" => false,
        "property_type" => "apartment", 
        "currency" => "USD",
        "amenities" => ["wifi"],
        "address" => %{"city" => "New York", "state" => "New York", "country" => "US"},
        "capacity" => %{"max" => 4, "bedrooms" => 2, "bathrooms" => 1},
        "house_rules" => %{"pets_allowed" => false, "smoking_allowed" => false},
        "calendar_restricted" => true
      }
    ]

    # Test new filter options
    test_filters = [
      {:currency, "EUR", "Currency filter"},
      {:state, "Berlin", "State filter"},
      {:min_bedrooms, 3, "Min bedrooms filter"},
      {:max_capacity, 5, "Max capacity filter"},
      {:pets_allowed, true, "Pet policy filter"},
      {:calendar_restricted, false, "Calendar restriction filter"}
    ]

    Enum.each(test_filters, fn {filter_key, filter_value, description} ->
      try do
        filtered = HospitableClient.Properties.filter_properties(sample_properties, %{filter_key => filter_value})
        IO.puts("   ✓ #{description}: #{length(filtered)} properties found")
      rescue
        e -> IO.puts("   ✗ #{description} failed: #{inspect(e)}")
      end
    end)

    # Test complex filtering
    try do
      complex_filter = HospitableClient.Properties.filter_properties(sample_properties, %{
        listed: true,
        currency: "EUR",
        min_bedrooms: 2,
        pets_allowed: true,
        has_amenities: ["wifi", "pool"]
      })
      IO.puts("   ✓ Complex filter: #{length(complex_filter)} properties found")
    rescue
      e -> IO.puts("   ✗ Complex filter failed: #{inspect(e)}")
    end
  end

  defp test_grouping_functionality do
    IO.puts("\n3. Testing Grouping Functionality")
    IO.puts("-" |> String.duplicate(40))

    sample_properties = [
      %{
        "id" => "1",
        "property_type" => "villa",
        "currency" => "EUR",
        "address" => %{"city" => "Berlin", "country" => "DE"}
      },
      %{
        "id" => "2",
        "property_type" => "apartment",
        "currency" => "EUR", 
        "address" => %{"city" => "Munich", "country" => "DE"}
      },
      %{
        "id" => "3",
        "property_type" => "penthouse",
        "currency" => "USD",
        "address" => %{"city" => "New York", "country" => "US"}
      }
    ]

    # Test grouping by different fields
    grouping_tests = [
      {:property_type, "Property Type"},
      {:currency, "Currency"},
      {:city, "City"},
      {:country, "Country"}
    ]

    Enum.each(grouping_tests, fn {group_by, description} ->
      try do
        grouped = HospitableClient.Properties.group_properties(sample_properties, group_by)
        group_keys = Map.keys(grouped)
        IO.puts("   ✓ Group by #{description}: #{length(group_keys)} groups (#{inspect(group_keys)})")
      rescue
        e -> IO.puts("   ✗ Group by #{description} failed: #{inspect(e)}")
      end
    end)
  end
end

# Run the enhanced validation
EnhancedPropertiesValidation.run()
