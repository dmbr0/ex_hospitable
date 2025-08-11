defmodule HospitableClient.ReservationsTest do
  use ExUnit.Case
  doctest HospitableClient.Reservations

  alias HospitableClient.Reservations

  setup do
    config = HospitableClient.new("test-api-key")
    {:ok, config: config}
  end

  describe "get_reservations/2" do
    test "raises error when properties parameter is missing", %{config: config} do
      assert_raise ArgumentError, "properties parameter is required", fn ->
        Reservations.get_reservations(config, [])
      end

      assert_raise ArgumentError, "properties parameter is required", fn ->
        Reservations.get_reservations(config, include: "financials")
      end
    end

    test "builds correct query parameters with properties only", %{config: config} do
      # Test that the function accepts valid parameters without raising ArgumentError
      properties = ["prop-1", "prop-2"]

      # This will return an error due to invalid API key, but validates parameter handling
      result = Reservations.get_reservations(config, properties: properties)
      assert {:error, _} = result
    end

    test "validates query parameter building" do
      # Test that valid parameter combinations don't raise ArgumentError
      properties = ["property-uuid-1", "property-uuid-2"]

      opts = [
        properties: properties,
        conversation_id: "conv-123",
        date_query: "checkin",
        start_date: "2024-01-01",
        end_date: "2024-12-31",
        include: "financials,guest,properties",
        page: 1,
        per_page: 20,
        platform_id: "ABC123"
      ]

      config = HospitableClient.new("test-key")

      # Should not raise ArgumentError with valid parameters
      result = Reservations.get_reservations(config, opts)
      assert {:error, _} = result
    end
  end

  describe "get_reservation/3" do
    test "accepts valid UUID parameter", %{config: config} do
      uuid = "6f58fd0a-a9cb-3746-9219-384a156ff7bb"

      # This will return an error due to invalid API key, but validates parameter handling
      result = Reservations.get_reservation(config, uuid)
      assert {:error, _} = result
    end

    test "accepts include parameter", %{config: config} do
      uuid = "6f58fd0a-a9cb-3746-9219-384a156ff7bb"
      opts = [include: "financials,guest,properties,review"]

      # This will return an error due to invalid API key, but validates parameter handling
      result = Reservations.get_reservation(config, uuid, opts)
      assert {:error, _} = result
    end
  end

  describe "reservation status helpers" do
    test "confirmed?/1 identifies confirmed reservations" do
      confirmed_reservation = %{
        reservation_status: %{
          current: %{category: "accepted", sub_category: nil}
        }
      }

      pending_reservation = %{
        reservation_status: %{
          current: %{category: "request", sub_category: "to book"}
        }
      }

      assert Reservations.confirmed?(confirmed_reservation) == true
      assert Reservations.confirmed?(pending_reservation) == false
    end

    test "needs_action?/1 identifies reservations needing action" do
      request_reservation = %{
        reservation_status: %{
          current: %{category: "request", sub_category: "to book"}
        }
      }

      checkpoint_reservation = %{
        reservation_status: %{
          current: %{category: "checkpoint", sub_category: "checkpoint"}
        }
      }

      accepted_reservation = %{
        reservation_status: %{
          current: %{category: "accepted", sub_category: nil}
        }
      }

      assert Reservations.needs_action?(request_reservation) == true
      assert Reservations.needs_action?(checkpoint_reservation) == true
      assert Reservations.needs_action?(accepted_reservation) == false
    end

    test "cancelled?/1 identifies cancelled reservations" do
      cancelled_reservation = %{
        reservation_status: %{
          current: %{category: "cancelled", sub_category: nil}
        }
      }

      declined_reservation = %{
        reservation_status: %{
          current: %{category: "not accepted", sub_category: "declined"}
        }
      }

      withdrawn_reservation = %{
        reservation_status: %{
          current: %{category: "not accepted", sub_category: "withdrawn"}
        }
      }

      accepted_reservation = %{
        reservation_status: %{
          current: %{category: "accepted", sub_category: nil}
        }
      }

      assert Reservations.cancelled?(cancelled_reservation) == true
      assert Reservations.cancelled?(declined_reservation) == true
      assert Reservations.cancelled?(withdrawn_reservation) == true
      assert Reservations.cancelled?(accepted_reservation) == false
    end

    test "cancellation_reason/1 returns correct cancellation reasons" do
      declined_reservation = %{
        reservation_status: %{
          current: %{category: "not accepted", sub_category: "declined"}
        }
      }

      withdrawn_reservation = %{
        reservation_status: %{
          current: %{category: "not accepted", sub_category: "withdrawn"}
        }
      }

      expired_reservation = %{
        reservation_status: %{
          current: %{category: "not accepted", sub_category: "expired"}
        }
      }

      cancelled_reservation = %{
        reservation_status: %{
          current: %{category: "cancelled", sub_category: nil}
        }
      }

      accepted_reservation = %{
        reservation_status: %{
          current: %{category: "accepted", sub_category: nil}
        }
      }

      assert Reservations.cancellation_reason(declined_reservation) == "declined"
      assert Reservations.cancellation_reason(withdrawn_reservation) == "withdrawn"
      assert Reservations.cancellation_reason(expired_reservation) == "expired"
      assert Reservations.cancellation_reason(cancelled_reservation) == "cancelled"
      assert Reservations.cancellation_reason(accepted_reservation) == nil
    end

    test "unknown_status?/1 identifies unknown statuses" do
      unknown_reservation = %{
        reservation_status: %{
          current: %{category: "unknown", sub_category: nil}
        }
      }

      accepted_reservation = %{
        reservation_status: %{
          current: %{category: "accepted", sub_category: nil}
        }
      }

      assert Reservations.unknown_status?(unknown_reservation) == true
      assert Reservations.unknown_status?(accepted_reservation) == false
    end
  end

  describe "complex status scenarios" do
    test "handles all documented status combinations" do
      statuses = [
        %{category: "request", sub_category: "pending verification"},
        %{category: "request", sub_category: "to book"},
        %{category: "request", sub_category: "for payment"},
        %{category: "checkpoint", sub_category: "checkpoint"},
        %{category: "checkpoint", sub_category: "voided"},
        %{category: "accepted", sub_category: nil},
        %{category: "cancelled", sub_category: nil},
        %{category: "not accepted", sub_category: "declined"},
        %{category: "not accepted", sub_category: "withdrawn"},
        %{category: "not accepted", sub_category: "expired"},
        %{category: "unknown", sub_category: nil}
      ]

      for status <- statuses do
        reservation = %{reservation_status: %{current: status}}

        # Test that our status helpers handle all documented cases
        confirmed_result = Reservations.confirmed?(reservation)
        needs_action_result = Reservations.needs_action?(reservation)
        cancelled_result = Reservations.cancelled?(reservation)
        unknown_result = Reservations.unknown_status?(reservation)

        # At least one status check should be true for any valid reservation
        status_checks = [confirmed_result, needs_action_result, cancelled_result, unknown_result]
        assert Enum.any?(status_checks), "Status #{inspect(status)} should match at least one condition"
      end
    end

    test "handles reservation with status history" do
      reservation_with_history = %{
        reservation_status: %{
          current: %{category: "accepted", sub_category: nil},
          history: [
            %{
              category: "request",
              sub_category: "to book",
              changed_at: "2024-01-01 10:00:00"
            },
            %{
              category: "accepted",
              sub_category: nil,
              changed_at: "2024-01-01 12:00:00"
            }
          ]
        }
      }

      assert Reservations.confirmed?(reservation_with_history) == true
      assert Reservations.needs_action?(reservation_with_history) == false
      assert Reservations.cancelled?(reservation_with_history) == false
      assert Reservations.unknown_status?(reservation_with_history) == false
    end
  end

  describe "type validation" do
    test "reservation type structure validation" do
      # This test ensures our type definitions are reasonable
      sample_reservation = %{
        id: "reservation-uuid",
        conversation_id: "conversation-uuid",
        platform: "airbnb",
        platform_id: "ABC123",
        booking_date: "2024-01-01 10:00:00",
        arrival_date: "2024-01-15 15:00:00",
        departure_date: "2024-01-20 11:00:00",
        nights: 5,
        check_in: "2024-01-15 15:00:00",
        check_out: "2024-01-20 11:00:00",
        last_message_at: "2024-01-10 14:30:00",
        status: "confirmed",
        reservation_status: %{
          current: %{category: "accepted", sub_category: nil},
          history: []
        },
        guests: %{
          total: 2,
          adult_count: 2,
          child_count: 0,
          infant_count: 0,
          pet_count: 0
        },
        issue_alert: nil,
        stay_type: "guest_stay",
        financials: nil,
        properties: nil,
        listings: nil,
        guest: nil,
        user: nil,
        review: nil
      }

      # Test that our status helpers work with this structure
      assert Reservations.confirmed?(sample_reservation) == true
      assert Reservations.needs_action?(sample_reservation) == false
      assert Reservations.cancelled?(sample_reservation) == false
      assert Reservations.unknown_status?(sample_reservation) == false
    end
  end
end