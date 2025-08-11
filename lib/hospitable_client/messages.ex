defmodule HospitableClient.Messages do
  @moduledoc """
  Messages API functionality for the Hospitable client.
  
  This module provides functions to interact with reservation message endpoints,
  including retrieving messages for a reservation and sending new messages.
  """

  @base_url "https://public.api.hospitable.com/v2"

  @type config :: HospitableClient.Config.config()
  @type uuid :: String.t()
  @type datetime :: String.t()

  @type attachment :: %{
          type: String.t(),
          url: String.t()
        }

  @type sender :: %{
          first_name: String.t(),
          full_name: String.t(),
          locale: String.t(),
          picture_url: String.t() | nil,
          thumbnail_url: String.t() | nil,
          location: String.t() | nil
        }

  @type user :: %{
          id: uuid(),
          email: String.t(),
          name: String.t()
        }

  @type message :: %{
          platform: String.t(),
          platform_id: integer(),
          conversation_id: uuid(),
          reservation_id: uuid(),
          content_type: String.t(),
          body: String.t(),
          attachments: list(attachment()),
          sender_type: String.t(),
          sender_role: String.t(),
          sender: sender(),
          user: user(),
          created_at: datetime(),
          source: String.t(),
          integration: String.t(),
          sent_reference_id: String.t()
        }

  @type messages_response :: %{
          data: list(message())
        }

  @type send_message_opts :: [
          body: String.t(),
          images: list(String.t())
        ]

  @type send_message_response :: %{
          data: %{
            sent_reference_id: String.t()
          }
        }

  @doc """
  Retrieves all messages for a specific reservation.

  ## Required Scope
  - `message:read`

  ## Parameters
  - `config`: Client configuration with API key and base URL
  - `reservation_uuid`: The UUID of the reservation to retrieve messages for

  ## Examples

      iex> config = HospitableClient.new("api-key")
      iex> # This would make an actual API request:
      iex> # {:ok, response} = HospitableClient.Messages.get_messages(config,
      iex> #   "becd1474-ccd1-40bf-9ce8-04456bfa338d"
      iex> # )
      iex> config.api_key
      "api-key"

  """
  @spec get_messages(config(), uuid()) :: {:ok, messages_response()} | {:error, term()}
  def get_messages(config, reservation_uuid) do
    url = "#{@base_url}/reservations/#{reservation_uuid}/messages"
    headers = HospitableClient.Auth.headers(config.api_key)

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, {:http_error, status_code, body}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end

  @doc """
  Sends a message to a reservation conversation.

  ## Required Scope
  - `message:write` (contact team-platform@hospitable.com to have this scope added)

  ## Rate Limits
  - Max 2 messages per minute to a single reservation
  - Max 50 messages every 5 minutes (across all reservations)

  ## Parameters
  - `config`: Client configuration with API key and base URL
  - `reservation_uuid`: The UUID of the reservation to send message to
  - `opts`: Message options (see `t:send_message_opts/0`)

  ## Options
  - `:body` (required) - The text of the message (HTML not supported, use \\n for line breaks)
  - `:images` - Array of image URLs to attach (max 3 images, 5MB each)

  ## Examples

      iex> config = HospitableClient.new("api-key")
      iex> # This would make an actual API request:
      iex> # {:ok, response} = HospitableClient.Messages.send_message(config,
      iex> #   "becd1474-ccd1-40bf-9ce8-04456bfa338d",
      iex> #   body: "Hello, guest!\\nYour check-in is at 3 PM.",
      iex> #   images: ["https://example.com/photo1.jpg"]
      iex> # )
      iex> config.api_key
      "api-key"

  """
  @spec send_message(config(), uuid(), send_message_opts()) ::
          {:ok, send_message_response()} | {:error, term()}
  def send_message(config, reservation_uuid, opts \\ []) do
    unless Keyword.has_key?(opts, :body) do
      raise ArgumentError, "body parameter is required for sending messages"
    end

    body = Keyword.get(opts, :body)
    images = Keyword.get(opts, :images, [])

    request_body =
      %{body: body}
      |> maybe_add_images(images)

    url = "#{@base_url}/reservations/#{reservation_uuid}/messages"
    headers = HospitableClient.Auth.headers(config.api_key)

    case HTTPoison.post(url, Jason.encode!(request_body), headers) do
      {:ok, %HTTPoison.Response{status_code: 202, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, {:http_error, status_code, body}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end

  # Private helper functions

  defp maybe_add_images(request_body, []), do: request_body
  defp maybe_add_images(request_body, images) when is_list(images) do
    Map.put(request_body, :images, images)
  end
end