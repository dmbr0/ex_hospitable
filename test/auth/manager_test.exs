defmodule HospitableClient.Auth.ManagerTest do
  use ExUnit.Case

  alias HospitableClient.Auth.Manager, as: AuthManager
  alias HospitableClient.Auth.Records
  require Records

  setup do
    # Clear authentication state before each test
    AuthManager.clear_auth()
    :ok
  end

  describe "token management" do
    test "set_token/1 stores token in credentials" do
      token = "test_token_123"
      assert :ok = AuthManager.set_token(token)

      {:ok, credentials} = AuthManager.get_credentials()
      assert Records.auth_credentials(credentials, :token) == token
      assert Records.auth_credentials(credentials, :token_type) == "Bearer"
    end

    test "get_token/0 returns stored token" do
      token = "test_token_456"
      AuthManager.set_token(token)

      assert {:ok, ^token} = AuthManager.get_token()
    end

    test "get_token/0 returns error when no token is set" do
      assert {:error, :no_token} = AuthManager.get_token()
    end

    test "authenticated?/0 reflects authentication state" do
      assert AuthManager.authenticated?() == false

      AuthManager.set_token("test_token")
      assert AuthManager.authenticated?() == true

      AuthManager.clear_auth()
      assert AuthManager.authenticated?() == false
    end
  end

  describe "credentials management" do
    test "get_credentials/0 returns error when no credentials are set" do
      assert {:error, :no_credentials} = AuthManager.get_credentials()
    end

    test "get_credentials/0 returns credentials with proper structure" do
      token = "test_token_789"
      AuthManager.set_token(token)

      {:ok, credentials} = AuthManager.get_credentials()
      assert Records.auth_credentials(credentials, :token) == token
      assert Records.auth_credentials(credentials, :token_type) == "Bearer"
      assert Records.auth_credentials(credentials, :created_at) != nil
    end
  end

  describe "state management" do
    test "clear_auth/0 resets authentication state" do
      AuthManager.set_token("test_token")
      assert AuthManager.authenticated?() == true

      AuthManager.clear_auth()
      assert AuthManager.authenticated?() == false
      assert {:error, :no_token} = AuthManager.get_token()
      assert {:error, :no_credentials} = AuthManager.get_credentials()
    end

    test "get_state/0 returns current state record" do
      state = AuthManager.get_state()
      assert Records.auth_state(state, :authenticated) == false
      assert Records.auth_state(state, :credentials) == nil

      AuthManager.set_token("test_token")
      new_state = AuthManager.get_state()
      assert Records.auth_state(new_state, :authenticated) == true
      assert Records.auth_state(new_state, :credentials) != nil
    end
  end
end
