defmodule HospitableClientTest do
  use ExUnit.Case
  doctest HospitableClient

  describe "HospitableClient.Auth" do
    test "headers/1 returns proper authorization headers" do
      api_key = "test-api-key"
      expected_headers = [
        {"Authorization", "Bearer test-api-key"},
        {"Content-Type", "application/json"}
      ]

      assert HospitableClient.Auth.headers(api_key) == expected_headers
    end

    test "valid_api_key?/1 validates API keys correctly" do
      assert HospitableClient.Auth.valid_api_key?("valid-key") == true
      assert HospitableClient.Auth.valid_api_key?("sk_test_123") == true
      assert HospitableClient.Auth.valid_api_key?("") == false
      assert HospitableClient.Auth.valid_api_key?(nil) == false
      assert HospitableClient.Auth.valid_api_key?(123) == false
    end
  end

  describe "HospitableClient.Config" do
    test "new/1 creates configuration with valid API key" do
      api_key = "test-api-key"
      config = HospitableClient.Config.new(api_key)

      assert config.api_key == api_key
      assert config.base_url == "https://api.hospitable.com"
    end

    test "new/2 allows base_url override" do
      api_key = "test-api-key"
      custom_url = "https://custom.hospitable.com"
      config = HospitableClient.Config.new(api_key, base_url: custom_url)

      assert config.api_key == api_key
      assert config.base_url == custom_url
    end

    test "new/1 raises error with invalid API key" do
      assert_raise ArgumentError, "API key must be a non-empty string", fn ->
        HospitableClient.Config.new("")
      end

      assert_raise ArgumentError, "API key must be a non-empty string", fn ->
        HospitableClient.Config.new(nil)
      end
    end

    test "get_api_key/0 returns API key from application config" do
      Application.put_env(:ex_hospitable, :api_key, "app-config-key")
      assert HospitableClient.Config.get_api_key() == {:ok, "app-config-key"}
      Application.delete_env(:ex_hospitable, :api_key)
    end

    test "get_api_key/0 returns API key from environment variable" do
      System.put_env("HOSPITABLE_API_KEY", "env-key")
      Application.delete_env(:ex_hospitable, :api_key)
      
      assert HospitableClient.Config.get_api_key() == {:ok, "env-key"}
      
      System.delete_env("HOSPITABLE_API_KEY")
    end

    test "get_api_key/0 returns error when no key is found" do
      Application.delete_env(:ex_hospitable, :api_key)
      System.delete_env("HOSPITABLE_API_KEY")
      
      assert HospitableClient.Config.get_api_key() == {:error, :not_found}
    end

    test "application config takes precedence over environment variable" do
      Application.put_env(:ex_hospitable, :api_key, "app-config-key")
      System.put_env("HOSPITABLE_API_KEY", "env-key")
      
      assert HospitableClient.Config.get_api_key() == {:ok, "app-config-key"}
      
      Application.delete_env(:ex_hospitable, :api_key)
      System.delete_env("HOSPITABLE_API_KEY")
    end
  end

  describe "HospitableClient" do
    test "new/1 creates client configuration" do
      api_key = "test-api-key"
      client = HospitableClient.new(api_key)

      assert client.api_key == api_key
      assert client.base_url == "https://api.hospitable.com"
    end

    test "from_env/0 creates client from environment configuration" do
      Application.put_env(:ex_hospitable, :api_key, "env-test-key")
      
      {:ok, client} = HospitableClient.from_env()
      assert client.api_key == "env-test-key"
      assert client.base_url == "https://api.hospitable.com"
      
      Application.delete_env(:ex_hospitable, :api_key)
    end

    test "from_env/0 returns error when no API key is configured" do
      Application.delete_env(:ex_hospitable, :api_key)
      System.delete_env("HOSPITABLE_API_KEY")
      
      assert HospitableClient.from_env() == {:error, :api_key_not_found}
    end
  end
end
