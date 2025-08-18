#!/usr/bin/env elixir

# Example script demonstrating HospitableClient Properties functionality
# Usage: ./properties_example.exs

# Note: This is a demonstration script. To use with real API calls,
# ensure you have HOSPITABLE_ACCESS_TOKEN set in your .env file

Mix.install([
  {:ex_hospitable, path: "."}
])

defmodule PropertiesExample do
  @moduledoc """
  Examples of using the HospitableClient Properties module.
  """

  def run_examples do
    IO.puts("🏠 HospitableClient Properties Module Examples")
    IO.puts("=" |> String.duplicate(50))

    # Set up authentication for examples
    setup_auth()

    # Example 1: Basic property listing
    basic_properties_example()

    # Example 2: Properties with pagination
    pagination_example()

    # Example 3: Properties with includes
    includes_example()

    # Example 4: Single property retrieval
    single_property_example()

    # Example 5: Advanced properties module features
    advanced_features_example()

    IO.puts("\n✅ All examples completed!")
    IO.puts("\n📖 To use with real API:")
    IO.puts("   1. Set HOSPITABLE_ACCESS_TOKEN in .env file")
    IO.puts("   2. Remove the mock data and run real API calls")
  end

  defp setup_auth do
    IO.puts("\n1. Setting up authentication...")
    HospitableClient.set_token("demo_token_for_examples")
    IO.puts("   ✓ Token set: #{HospitableClient.authenticated?()}")
  end

  defp basic_properties_example do
    IO.puts("\n2. Basic Properties Listing")
    IO.puts("-" |> String.duplicate(30))
    
    # Using main module convenience function
    IO.puts("   Using HospitableClient.get_properties():")
    IO.puts("   # This would make: GET /v2/properties")
    IO.puts("   # Result: paginated list of properties")
    
    # Using Properties module directly
    IO.puts("\n   Using HospitableClient.Properties.get_properties():")
    IO.puts("   # Same API call, more explicit module usage")
  end

  defp pagination_example do
    IO.puts("\n3. Properties with Pagination")
    IO.puts("-" |> String.duplicate(30))
    
    IO.puts("   Getting page 2 with 25 properties per page:")
    IO.puts("   HospitableClient.get_properties(%{page: 2, per_page: 25})")
    IO.puts("   # Makes: GET /v2/properties?page=2&per_page=25")
    
    IO.puts("\n   Getting all properties across all pages:")
    IO.puts("   HospitableClient.Properties.get_all_properties()")
    IO.puts("   # Automatically handles pagination, fetches all pages")
  end

  defp includes_example do
    IO.puts("\n4. Properties with Related Resources")
    IO.puts("-" |> String.duplicate(30))
    
    IO.puts("   Including listings and user data:")
    IO.puts("   HospitableClient.get_properties(%{include: \"listings,user\"})")
    IO.puts("   # Makes: GET /v2/properties?include=listings,user")
    IO.puts("   # Result includes 'included' array with related data")
    
    IO.puts("\n   Available includes:")
    IO.puts("   - listings (requires listing:read scope)")
    IO.puts("   - user")
    IO.puts("   - details")
    IO.puts("   - bookings")
  end

  defp single_property_example do
    IO.puts("\n5. Single Property Retrieval")
    IO.puts("-" |> String.duplicate(30))
    
    property_id = "550e8400-e29b-41d4-a716-446655440000"
    
    IO.puts("   Getting single property:")
    IO.puts("   HospitableClient.get_property(\"#{property_id}\")")
    IO.puts("   # Makes: GET /v2/properties/#{property_id}")
    
    IO.puts("\n   With included resources:")
    IO.puts("   HospitableClient.get_property(\"#{property_id}\", %{include: \"listings\"})")
    IO.puts("   # Makes: GET /v2/properties/#{property_id}?include=listings")
  end

  defp advanced_features_example do
    IO.puts("\n6. Advanced Properties Module Features")
    IO.puts("-" |> String.duplicate(30))
    
    # Mock some property data for demonstration
    sample_properties = [
      %{
        "id" => "prop-1",
        "name" => "Berlin Apartment",
        "listed" => true,
        "amenities" => ["wifi", "kitchen", "parking"],
        "address" => %{"city" => "Berlin", "country" => "DE"},
        "capacity" => %{"max" => 4},
        "property_type" => "apartment"
      },
      %{
        "id" => "prop-2", 
        "name" => "Munich Studio",
        "listed" => false,
        "amenities" => ["wifi"],
        "address" => %{"city" => "Munich", "country" => "DE"},
        "capacity" => %{"max" => 2},
        "property_type" => "studio"
      }
    ]
    
    IO.puts("   Listing all unique amenities:")
    amenities = HospitableClient.Properties.list_amenities(sample_properties)
    IO.puts("   #{inspect(amenities)}")
    
    IO.puts("\n   Filtering properties (client-side):")
    
    # Filter by listed status
    listed_properties = HospitableClient.Properties.filter_properties(
      sample_properties, 
      %{listed: true}
    )
    IO.puts("   Listed properties: #{length(listed_properties)} found")
    
    # Filter by city
    berlin_properties = HospitableClient.Properties.filter_properties(
      sample_properties,
      %{city: "Berlin"}
    )
    IO.puts("   Berlin properties: #{length(berlin_properties)} found")
    
    # Filter by amenities
    kitchen_properties = HospitableClient.Properties.filter_properties(
      sample_properties,
      %{has_amenities: ["kitchen"]}
    )
    IO.puts("   Properties with kitchen: #{length(kitchen_properties)} found")
    
    # Multiple filters
    large_listed_properties = HospitableClient.Properties.filter_properties(
      sample_properties,
      %{listed: true, min_capacity: 3}
    )
    IO.puts("   Large listed properties: #{length(large_listed_properties)} found")
    
    IO.puts("\n   Available filter options:")
    IO.puts("   - listed: true/false")
    IO.puts("   - property_type: string")
    IO.puts("   - room_type: string")
    IO.puts("   - min_capacity: integer")
    IO.puts("   - city: string (case insensitive)")
    IO.puts("   - country: string (case insensitive)")
    IO.puts("   - has_amenities: list of required amenities")
  end
end

# Run the examples
PropertiesExample.run_examples()
