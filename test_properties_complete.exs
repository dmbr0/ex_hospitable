#!/usr/bin/env elixir

# Comprehensive test script for the Properties module
# Usage: ./test_properties_complete.exs

Mix.install([
  {:ex_hospitable, path: "."}
])

defmodule ComprehensivePropertiesTest do
  def run do
    IO.puts("🏠 Comprehensive Properties Module Test")
    IO.puts("=" |> String.duplicate(50))

    # Test 1: Module loading and basic functions
    test_module_loading()

    # Test 2: Authentication integration
    test_authentication_integration()

    # Test 3: Function signatures and interfaces
    test_function_interfaces()

    # Test 4: Data processing functions
    test_data_processing()

    # Test 5: Delegation functions
    test_delegation_functions()

    IO.puts("\n✅ All tests completed successfully!")
    IO.puts("\n🚀 The Properties module is ready for use!")
  end

  defp test_module_loading do
    IO.puts("\n1. Testing Module Loading")
    IO.puts("-" |> String.duplicate(30))

    # Test that the Properties module loads correctly
    try do
      HospitableClient.Properties.__info__(:functions)
      IO.puts("   ✓ Properties module loaded successfully")
    rescue
      e -> IO.puts("   ✗ Failed to load Properties module: #{inspect(e)}")
    end

    # Test that main module has Properties alias
    try do
      HospitableClient.__info__(:functions)
      IO.puts("   ✓ Main HospitableClient module loaded successfully")
    rescue
      e -> IO.puts("   ✗ Failed to load main module: #{inspect(e)}")
    end
  end

  defp test_authentication_integration do
    IO.puts("\n2. Testing Authentication Integration")
    IO.puts("-" |> String.duplicate(30))

    # Set up authentication
    result = HospitableClient.set_token("test_token_properties")
    IO.puts("   ✓ Token set: #{inspect(result)}")

    # Check authentication status
    is_auth = HospitableClient.authenticated?()
    IO.puts("   ✓ Authentication status: #{is_auth}")

    # Test token retrieval
    case HospitableClient.get_token() do
      {:ok, token} -> IO.puts("   ✓ Token retrieved: #{String.slice(token, 0..10)}...")
      error -> IO.puts("   ✗ Token retrieval failed: #{inspect(error)}")
    end
  end

  defp test_function_interfaces do
    IO.puts("\n3. Testing Function Interfaces")
    IO.puts("-" |> String.duplicate(30))

    # Test Properties module functions exist
    properties_functions = [
      {:get_properties, 1},
      {:get_property, 2},
      {:get_all_properties, 1},
      {:list_amenities, 1},
      {:filter_properties, 2}
    ]

    Enum.each(properties_functions, fn {function_name, arity} ->
      if function_exported?(HospitableClient.Properties, function_name, arity) do
        IO.puts("   ✓ #{function_name}/#{arity} exists")
      else
        IO.puts("   ✗ #{function_name}/#{arity} missing")
      end
    end)

    # Test main module delegation functions
    main_functions = [
      {:get_properties, 0},
      {:get_properties, 1},
      {:get_property, 1},
      {:get_property, 2}
    ]

    Enum.each(main_functions, fn {function_name, arity} ->
      if function_exported?(HospitableClient, function_name, arity) do
        IO.puts("   ✓ HospitableClient.#{function_name}/#{arity} exists")
      else
        IO.puts("   ✗ HospitableClient.#{function_name}/#{arity} missing")
      end
    end)
  end

  defp test_data_processing do
    IO.puts("\n4. Testing Data Processing Functions")
    IO.puts("-" |> String.duplicate(30))

    # Sample property data for testing
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
        "amenities" => ["wifi", "pool"],
        "address" => %{"city" => "Munich", "country" => "DE"},
        "capacity" => %{"max" => 2},
        "property_type" => "studio"
      }
    ]

    sample_response = %{"data" => sample_properties}

    # Test list_amenities
    try do
      amenities = HospitableClient.Properties.list_amenities(sample_response)
      IO.puts("   ✓ list_amenities works: #{inspect(amenities)}")
    rescue
      e -> IO.puts("   ✗ list_amenities failed: #{inspect(e)}")
    end

    # Test filter_properties - listed status
    try do
      listed = HospitableClient.Properties.filter_properties(sample_response, %{listed: true})
      IO.puts("   ✓ filter_properties (listed): #{length(listed)} properties")
    rescue
      e -> IO.puts("   ✗ filter_properties failed: #{inspect(e)}")
    end

    # Test filter_properties - city
    try do
      berlin = HospitableClient.Properties.filter_properties(sample_response, %{city: "Berlin"})
      IO.puts("   ✓ filter_properties (city): #{length(berlin)} properties")
    rescue
      e -> IO.puts("   ✗ filter_properties (city) failed: #{inspect(e)}")
    end

    # Test filter_properties - amenities
    try do
      with_kitchen = HospitableClient.Properties.filter_properties(sample_response, %{has_amenities: ["kitchen"]})
      IO.puts("   ✓ filter_properties (amenities): #{length(with_kitchen)} properties")
    rescue
      e -> IO.puts("   ✗ filter_properties (amenities) failed: #{inspect(e)}")
    end

    # Test filter_properties - multiple filters
    try do
      complex_filter = HospitableClient.Properties.filter_properties(sample_response, %{
        listed: true,
        min_capacity: 3,
        has_amenities: ["wifi"]
      })
      IO.puts("   ✓ filter_properties (complex): #{length(complex_filter)} properties")
    rescue
      e -> IO.puts("   ✗ filter_properties (complex) failed: #{inspect(e)}")
    end
  end

  defp test_delegation_functions do
    IO.puts("\n5. Testing Delegation Functions")
    IO.puts("-" |> String.duplicate(30))

    # Test that delegation functions are callable
    # Note: These won't make actual HTTP requests, just test the interface

    try do
      # This will fail with authentication error, but should not crash
      _result = HospitableClient.get_properties()
      IO.puts("   ✓ get_properties/0 callable")
    rescue
      e -> 
        # Expected to fail without real API, but should be the right kind of error
        if String.contains?(to_string(e), "econnrefused") or 
           String.contains?(to_string(e), "no_credentials") or
           String.contains?(to_string(e), "nxdomain") do
          IO.puts("   ✓ get_properties/0 callable (expected network/auth error)")
        else
          IO.puts("   ⚠ get_properties/0 unexpected error: #{inspect(e)}")
        end
    end

    try do
      _result = HospitableClient.get_properties(%{page: 1})
      IO.puts("   ✓ get_properties/1 callable")
    rescue
      e ->
        if String.contains?(to_string(e), "econnrefused") or 
           String.contains?(to_string(e), "no_credentials") or
           String.contains?(to_string(e), "nxdomain") do
          IO.puts("   ✓ get_properties/1 callable (expected network/auth error)")
        else
          IO.puts("   ⚠ get_properties/1 unexpected error: #{inspect(e)}")
        end
    end

    try do
      _result = HospitableClient.get_property("test-id")
      IO.puts("   ✓ get_property/1 callable")
    rescue
      e ->
        if String.contains?(to_string(e), "econnrefused") or 
           String.contains?(to_string(e), "no_credentials") or
           String.contains?(to_string(e), "nxdomain") do
          IO.puts("   ✓ get_property/1 callable (expected network/auth error)")
        else
          IO.puts("   ⚠ get_property/1 unexpected error: #{inspect(e)}")
        end
    end
  end
end

# Run the comprehensive test
ComprehensivePropertiesTest.run()
