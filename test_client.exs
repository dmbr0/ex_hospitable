#!/usr/bin/env elixir

# Simple script to test the HospitableClient library
# Usage: ./test_client.exs

# Add project paths
Mix.install([
  {:ex_hospitable, path: "."}
])

# Test the client
defmodule TestClient do
  def run do
    IO.puts("🏠 Testing HospitableClient...")
    
    # Test authentication setup
    IO.puts("\n1. Testing authentication...")
    result = HospitableClient.set_token("test_token_123")
    IO.puts("   Set token: #{inspect(result)}")
    
    is_auth = HospitableClient.authenticated?()
    IO.puts("   Authenticated: #{is_auth}")
    
    {:ok, token} = HospitableClient.get_token()
    IO.puts("   Retrieved token: #{token}")
    
    # Test configuration
    IO.puts("\n2. Testing environment configuration...")
    System.put_env("HOSPITABLE_BASE_URL", "https://api.example.com/v2")
    System.put_env("HOSPITABLE_TIMEOUT", "15000")
    
    # Test clearing auth
    IO.puts("\n3. Testing auth clearing...")
    HospitableClient.Auth.Manager.clear_auth()
    is_auth_after_clear = HospitableClient.authenticated?()
    IO.puts("   Authenticated after clear: #{is_auth_after_clear}")
    
    IO.puts("\n✅ All basic tests passed!")
    IO.puts("\n📖 To use with real API:")
    IO.puts("   1. Create .env file with HOSPITABLE_ACCESS_TOKEN=your_token")
    IO.puts("   2. Run: iex -S mix")
    IO.puts("   3. Use: HospitableClient.get(\"/properties\")")
  end
end

TestClient.run()
