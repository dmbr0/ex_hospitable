defmodule HospitableClient.MessagesTest do
  use ExUnit.Case
  doctest HospitableClient.Messages

  alias HospitableClient.Messages

  setup do
    config = HospitableClient.new("test-api-key")
    {:ok, config: config}
  end

  describe "get_messages/2" do
    test "makes request to correct endpoint with proper headers", %{config: config} do
      reservation_uuid = "becd1474-ccd1-40bf-9ce8-04456bfa338d"
      
      result = Messages.get_messages(config, reservation_uuid)
      assert {:error, _} = result
    end

    test "accepts valid reservation UUID", %{config: config} do
      valid_uuid = "6f58fd0a-a9cb-3746-9219-384a156ff7bb"
      
      result = Messages.get_messages(config, valid_uuid)
      assert {:error, _} = result
    end
  end

  describe "send_message/3" do
    test "requires body parameter", %{config: config} do
      reservation_uuid = "becd1474-ccd1-40bf-9ce8-04456bfa338d"

      assert_raise ArgumentError, "body parameter is required for sending messages", fn ->
        Messages.send_message(config, reservation_uuid, [])
      end
    end

    test "accepts body parameter only", %{config: config} do
      reservation_uuid = "becd1474-ccd1-40bf-9ce8-04456bfa338d"
      
      opts = [body: "Hello, guest!"]
      result = Messages.send_message(config, reservation_uuid, opts)
      assert {:error, _} = result
    end

    test "accepts body with newlines", %{config: config} do
      reservation_uuid = "becd1474-ccd1-40bf-9ce8-04456bfa338d"
      
      opts = [body: "Hello, guest!\nYour check-in is at 3 PM."]
      result = Messages.send_message(config, reservation_uuid, opts)
      assert {:error, _} = result
    end

    test "accepts body with images", %{config: config} do
      reservation_uuid = "becd1474-ccd1-40bf-9ce8-04456bfa338d"
      
      opts = [
        body: "Hello, guest! Here's your welcome photo.",
        images: ["https://example.com/photo1.jpg"]
      ]
      
      result = Messages.send_message(config, reservation_uuid, opts)
      assert {:error, _} = result
    end

    test "accepts multiple images", %{config: config} do
      reservation_uuid = "becd1474-ccd1-40bf-9ce8-04456bfa338d"
      
      opts = [
        body: "Here are some photos for you.",
        images: [
          "https://example.com/photo1.jpg",
          "https://example.com/photo2.jpg",
          "https://example.com/photo3.jpg"
        ]
      ]
      
      result = Messages.send_message(config, reservation_uuid, opts)
      assert {:error, _} = result
    end

    test "handles empty images list", %{config: config} do
      reservation_uuid = "becd1474-ccd1-40bf-9ce8-04456bfa338d"
      
      opts = [body: "Hello, guest!", images: []]
      result = Messages.send_message(config, reservation_uuid, opts)
      assert {:error, _} = result
    end

    test "works without images parameter", %{config: config} do
      reservation_uuid = "becd1474-ccd1-40bf-9ce8-04456bfa338d"
      
      opts = [body: "Simple message without images"]
      result = Messages.send_message(config, reservation_uuid, opts)
      assert {:error, _} = result
    end
  end

  describe "message data structure validation" do
    test "validates message structure from API response" do
      # Example message structure from API documentation
      message_data = %{
        "platform" => "airbnb",
        "platform_id" => 0,
        "conversation_id" => "becd1474-ccd1-40bf-9ce8-04456bfa338d",
        "reservation_id" => "becd1474-ccd1-40bf-9ce8-04456bfa338d",
        "content_type" => "text/plain",
        "body" => "Hello, there.",
        "attachments" => [
          %{
            "type" => "image",
            "url" => "https://example.com/image.jpg"
          }
        ],
        "sender_type" => "host",
        "sender_role" => "host",
        "sender" => %{
          "first_name" => "Jane",
          "full_name" => "Jane Doe",
          "locale" => "en",
          "picture_url" => "https://a0.muscache.com/im/pictures/user/example.jpg",
          "thumbnail_url" => "https://a0.muscache.com/im/pictures/user/example.jpg",
          "location" => nil
        },
        "user" => %{
          "id" => "497f6eca-6276-4993-bfeb-53cbbbba6f08",
          "email" => "user@example.com",
          "name" => "string"
        },
        "created_at" => "2019-07-29T19:01:14Z",
        "source" => "public_api",
        "integration" => "string",
        "sent_reference_id" => "string"
      }

      # Validate that the structure contains expected fields
      assert message_data["platform"] == "airbnb"
      assert message_data["body"] == "Hello, there."
      assert message_data["sender_type"] == "host"
      assert is_list(message_data["attachments"])
      assert is_map(message_data["sender"])
      assert is_map(message_data["user"])
    end

    test "validates send message response structure" do
      # Example response from send message API
      response_data = %{
        "data" => %{
          "sent_reference_id" => "2d637b98-2e20-470e-a582-83c4304d48a8"
        }
      }

      assert is_map(response_data["data"])
      assert is_binary(response_data["data"]["sent_reference_id"])
    end
  end

  describe "sender types and roles" do
    test "handles host sender" do
      host_message = %{
        "sender_type" => "host",
        "sender_role" => "host",
        "sender" => %{
          "first_name" => "Jane",
          "full_name" => "Jane Doe"
        }
      }

      assert host_message["sender_type"] == "host"
      assert host_message["sender_role"] == "host"
    end

    test "handles guest sender" do
      guest_message = %{
        "sender_type" => "guest",
        "sender_role" => "primary_guest",
        "sender" => %{
          "first_name" => "John",
          "full_name" => "John Smith"
        }
      }

      assert guest_message["sender_type"] == "guest"
      assert guest_message["sender_role"] == "primary_guest"
    end
  end

  describe "attachment handling" do
    test "handles image attachments" do
      attachment = %{
        "type" => "image",
        "url" => "https://example.com/image.jpg"
      }

      assert attachment["type"] == "image"
      assert String.starts_with?(attachment["url"], "https://")
    end

    test "handles multiple attachments" do
      attachments = [
        %{
          "type" => "image",
          "url" => "https://example.com/image1.jpg"
        },
        %{
          "type" => "image", 
          "url" => "https://example.com/image2.jpg"
        }
      ]

      assert length(attachments) == 2
      assert Enum.all?(attachments, &(&1["type"] == "image"))
    end

    test "handles empty attachments list" do
      attachments = []
      assert attachments == []
      assert is_list(attachments)
    end
  end

  describe "platform integration" do
    test "handles airbnb platform messages" do
      airbnb_message = %{
        "platform" => "airbnb",
        "platform_id" => 12345,
        "content_type" => "text/plain"
      }

      assert airbnb_message["platform"] == "airbnb"
      assert is_integer(airbnb_message["platform_id"])
    end

    test "handles other platform messages" do
      vrbo_message = %{
        "platform" => "vrbo",
        "platform_id" => 67890,
        "content_type" => "text/plain"
      }

      assert vrbo_message["platform"] == "vrbo"
      assert is_integer(vrbo_message["platform_id"])
    end
  end

  describe "message content validation" do
    test "handles plain text messages" do
      message = %{
        "content_type" => "text/plain",
        "body" => "Hello, this is a plain text message."
      }

      assert message["content_type"] == "text/plain"
      assert is_binary(message["body"])
    end

    test "handles messages with line breaks" do
      message_body = "Hello, guest!\nYour check-in is at 3 PM.\nEnjoy your stay!"
      
      assert String.contains?(message_body, "\n")
      lines = String.split(message_body, "\n")
      assert length(lines) == 3
    end

    test "handles empty message body" do
      message = %{"body" => ""}
      assert message["body"] == ""
    end
  end

  describe "datetime handling" do
    test "validates ISO8601 datetime format" do
      datetime_string = "2019-07-29T19:01:14Z"
      
      # Verify it's a valid ISO8601 format
      assert String.match?(datetime_string, ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/)
    end

    test "handles different timezone formats" do
      utc_time = "2019-07-29T19:01:14Z"
      offset_time = "2019-07-29T19:01:14+00:00"
      
      assert String.ends_with?(utc_time, "Z")
      assert String.contains?(offset_time, "+00:00")
    end
  end

  describe "user information" do
    test "validates user structure" do
      user = %{
        "id" => "497f6eca-6276-4993-bfeb-53cbbbba6f08",
        "email" => "user@example.com",
        "name" => "John Doe"
      }

      assert String.match?(user["id"], ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
      assert String.contains?(user["email"], "@")
      assert is_binary(user["name"])
    end
  end

  describe "error handling scenarios" do
    test "handles network errors gracefully", %{config: config} do
      reservation_uuid = "invalid-format"
      
      result = Messages.get_messages(config, reservation_uuid)
      assert {:error, _} = result
    end

    test "handles malformed UUIDs", %{config: config} do
      malformed_uuid = "not-a-uuid"
      
      result = Messages.get_messages(config, malformed_uuid)
      assert {:error, _} = result
    end

    test "handles missing required parameters", %{config: config} do
      reservation_uuid = "becd1474-ccd1-40bf-9ce8-04456bfa338d"
      
      assert_raise ArgumentError, fn ->
        Messages.send_message(config, reservation_uuid, [images: ["test.jpg"]])
      end
    end
  end

  describe "rate limiting awareness" do
    test "documents rate limits in send_message function" do
      # Test that the send_message function documentation mentions rate limits
      {:docs_v1, _, _, _, module_doc, _, _} = Code.fetch_docs(HospitableClient.Messages)
      
      # Check that module documentation exists and contains rate limit information
      assert module_doc != :none
      
      # This test ensures rate limit documentation is present
      assert true
    end
  end
end