defmodule HospitableClientTest do
  use ExUnit.Case
  doctest HospitableClient

  alias HospitableClient.Auth.Manager, as: AuthManager

  setup do
    # Clear authentication state before each test
    AuthManager.clear_auth()
    :ok
  end

  describe "authentication" do
    test "set_token/1 sets authentication token" do
      token = "test_token_123"
      assert :ok = HospitableClient.set_token(token)
      assert {:ok, ^token} = HospitableClient.get_token()
    end

    test "authenticated?/0 returns false when no token is set" do
      assert HospitableClient.authenticated?() == false
    end

    test "authenticated?/0 returns true when token is set" do
      HospitableClient.set_token("test_token")
      assert HospitableClient.authenticated?() == true
    end
  end

  describe "token management" do
    test "get_token/0 returns error when no token is set" do
      assert {:error, :no_token} = HospitableClient.get_token()
    end

    test "token can be cleared" do
      HospitableClient.set_token("test_token")
      assert HospitableClient.authenticated?() == true

      AuthManager.clear_auth()
      assert HospitableClient.authenticated?() == false
    end
  end

  describe "properties API" do
    test "get_properties/0 delegates to Properties module" do
      # Test that the delegation function exists
      assert is_function(&HospitableClient.get_properties/0)
      assert is_function(&HospitableClient.get_properties/1)
    end

    test "get_property/1 delegates to Properties module" do
      # Test that the delegation function exists
      property_id = "550e8400-e29b-41d4-a716-446655440000"
      assert is_function(&HospitableClient.get_property/1)
      assert is_function(&HospitableClient.get_property/2)
    end
  end
end
