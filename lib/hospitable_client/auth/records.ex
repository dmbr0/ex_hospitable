defmodule HospitableClient.Auth.Records do
  @moduledoc """
  Record definitions for authentication-related data structures.

  This module defines Erlang records used throughout the authentication
  system for consistent data handling.
  """

  require Record

  @doc """
  Authentication credentials record.

  Fields:
  - token: The access token (Personal Access Token)
  - token_type: Type of token (default: "Bearer")
  - expires_at: Optional expiration timestamp (for future OAuth2 support)
  - refresh_token: Optional refresh token (for future OAuth2 support)
  - created_at: Timestamp when credentials were created
  """
  Record.defrecord(:auth_credentials,
    token: nil,
    token_type: "Bearer",
    expires_at: nil,
    refresh_token: nil,
    created_at: nil
  )

  @doc """
  Authentication state record.

  Fields:
  - credentials: The current authentication credentials
  - authenticated: Boolean indicating if currently authenticated
  - last_validated: Timestamp of last token validation
  - validation_attempts: Number of consecutive failed validation attempts
  """
  Record.defrecord(:auth_state,
    credentials: nil,
    authenticated: false,
    last_validated: nil,
    validation_attempts: 0
  )

  @type auth_credentials ::
          record(:auth_credentials,
            token: String.t() | nil,
            token_type: String.t(),
            expires_at: DateTime.t() | nil,
            refresh_token: String.t() | nil,
            created_at: DateTime.t() | nil
          )

  @type auth_state ::
          record(:auth_state,
            credentials: auth_credentials() | nil,
            authenticated: boolean(),
            last_validated: DateTime.t() | nil,
            validation_attempts: non_neg_integer()
          )
end
