# HospitableClient Examples

This document provides comprehensive usage examples for the HospitableClient library.

## Table of Contents
- [Reservations API Examples](#reservations-api-examples)
- [Properties API Examples](#properties-api-examples)
- [Messages API Examples](#messages-api-examples)
- [Interactive Shell Usage](#interactive-shell-usage)

## Reservations API Examples

### Basic Reservation Operations

```elixir
# Get multiple reservations with filtering
client = HospitableClient.new("your-api-key")

{:ok, response} = HospitableClient.get_reservations(client, 
  properties: ["property-uuid-1", "property-uuid-2"]
)

# With filtering and includes
{:ok, response} = HospitableClient.get_reservations(client,
  properties: ["property-uuid"],
  start_date: "2024-01-01",
  end_date: "2024-12-31",
  include: "financials,guest,properties",
  page: 1,
  per_page: 20
)

# Search by platform ID
{:ok, response} = HospitableClient.get_reservations(client,
  properties: ["property-uuid"],
  platform_id: "ABC123"
)
```

### Single Reservation Operations

```elixir
# Get reservation by UUID
{:ok, response} = HospitableClient.get_reservation(client,
  "6f58fd0a-a9cb-3746-9219-384a156ff7bb"
)

# With additional data included
{:ok, response} = HospitableClient.get_reservation(client,
  "6f58fd0a-a9cb-3746-9219-384a156ff7bb",
  include: "financials,guest,properties,review"
)
```

### Reservation Status Management

```elixir
# Check if reservation is confirmed
if HospitableClient.Reservations.confirmed?(reservation) do
  IO.puts("Reservation is confirmed!")
end

# Check if reservation needs action
if HospitableClient.Reservations.needs_action?(reservation) do
  IO.puts("This reservation requires attention")
end

# Check if reservation was cancelled
if HospitableClient.Reservations.cancelled?(reservation) do
  reason = HospitableClient.Reservations.cancellation_reason(reservation)
  IO.puts("Reservation was cancelled: #{reason}")
end

# Handle unknown statuses safely
if HospitableClient.Reservations.unknown_status?(reservation) do
  IO.warn("Unknown reservation status detected: #{reservation.id}")
end
```

## Properties API Examples

### Get All Properties

```elixir
# Basic usage - get all properties
client = HospitableClient.new("your-api-key")

{:ok, response} = HospitableClient.get_properties(client)

# With pagination and includes
{:ok, response} = HospitableClient.get_properties(client,
  include: "user,listings,details,bookings",
  page: 1,
  per_page: 50
)

# Access property data
properties = response["data"]
first_property = List.first(properties)
```

### Search Available Properties

```elixir
# Basic search - find properties for specific dates and guests
{:ok, results} = HospitableClient.search_properties(client,
  adults: 2,
  start_date: "2024-08-16", 
  end_date: "2024-08-21"
)

# Family search with children and pets
{:ok, results} = HospitableClient.search_properties(client,
  adults: 2,
  children: 2,
  infants: 1,
  pets: 1,
  start_date: "2024-12-20",
  end_date: "2024-12-27",
  include: "listings,details"
)

# Location-based search
{:ok, results} = HospitableClient.search_properties(client,
  adults: 2,
  start_date: "2024-09-01",
  end_date: "2024-09-07",
  location: %{latitude: 52.520008, longitude: 13.404954}
)
```

### Property Helper Functions

```elixir
# Check property rules and amenities
if HospitableClient.Properties.pet_friendly?(property) do
  IO.puts("This property welcomes pets!")
end

if HospitableClient.Properties.smoking_allowed?(property) do
  IO.puts("Smoking is allowed")
end

if HospitableClient.Properties.events_allowed?(property) do
  IO.puts("Events are welcome")
end

# Check availability and capacity
max_guests = HospitableClient.Properties.max_guests(property)
IO.puts("Maximum guests: #{max_guests}")

# For search results, check availability
if HospitableClient.Properties.available?(search_result) do
  IO.puts("Property is available for your dates")
else
  reasons = HospitableClient.Properties.unavailability_reasons(search_result)
  IO.puts("Unavailable due to: #{Enum.join(reasons, ", ")}")
end
```

## Messages API Examples

### Get Reservation Messages

```elixir
# Get all messages for a reservation
client = HospitableClient.new("your-api-key")

{:ok, response} = HospitableClient.get_messages(client,
  "becd1474-ccd1-40bf-9ce8-04456bfa338d"
)

# Access message data
messages = response["data"]
first_message = List.first(messages)

# Check message details
first_message["body"]          # => "Hello, there."
first_message["sender_type"]   # => "host" or "guest"
first_message["created_at"]    # => "2019-07-29T19:01:14Z"
```

### Send Messages to Reservations

```elixir
# Send a simple text message
{:ok, response} = HospitableClient.send_message(client,
  "becd1474-ccd1-40bf-9ce8-04456bfa338d",
  body: "Hello, guest! Welcome to our property."
)

# Get the sent reference ID
sent_id = response["data"]["sent_reference_id"]
# => "2d637b98-2e20-470e-a582-83c4304d48a8"

# Send a message with line breaks
{:ok, response} = HospitableClient.send_message(client,
  "becd1474-ccd1-40bf-9ce8-04456bfa338d",
  body: "Hello, guest!\nYour check-in is at 3 PM.\nEnjoy your stay!"
)

# Send a message with image attachments
{:ok, response} = HospitableClient.send_message(client,
  "becd1474-ccd1-40bf-9ce8-04456bfa338d",
  body: "Here's your welcome package and property photos!",
  images: [
    "https://example.com/welcome-guide.jpg",
    "https://example.com/property-photo.jpg"
  ]
)
```

### Message Data Analysis

```elixir
# Get messages and analyze conversation
{:ok, response} = HospitableClient.get_messages(client, reservation_uuid)
messages = response["data"]

# Count messages by sender type
host_messages = Enum.filter(messages, &(&1["sender_type"] == "host"))
guest_messages = Enum.filter(messages, &(&1["sender_type"] == "guest"))

IO.puts("Host messages: #{length(host_messages)}")
IO.puts("Guest messages: #{length(guest_messages)}")

# Find messages with attachments
messages_with_attachments = Enum.filter(messages, fn message ->
  length(message["attachments"]) > 0
end)

# Get recent messages (last 24 hours)
one_day_ago = DateTime.utc_now() |> DateTime.add(-86400, :second)
recent_messages = Enum.filter(messages, fn message ->
  {:ok, created_at, _} = DateTime.from_iso8601(message["created_at"])
  DateTime.compare(created_at, one_day_ago) == :gt
end)

# Check for unread messages (implement based on your business logic)
unread_messages = Enum.filter(messages, fn message ->
  message["sender_type"] == "guest" and
  message["source"] != "public_api"  # Messages not sent via API
end)
```

### Working with Message Attachments

```elixir
# Send message with multiple images (max 3 images, 5MB each)
{:ok, response} = HospitableClient.send_message(client,
  reservation_uuid,
  body: "Here are the property details and local attractions:",
  images: [
    "https://yourcdn.com/property-guide.jpg",
    "https://yourcdn.com/local-map.jpg", 
    "https://yourcdn.com/wifi-instructions.jpg"
  ]
)

# Handle messages with attachments when receiving
{:ok, response} = HospitableClient.get_messages(client, reservation_uuid)
messages = response["data"]

Enum.each(messages, fn message ->
  if length(message["attachments"]) > 0 do
    IO.puts("Message from #{message["sender"]["full_name"]} has #{length(message["attachments"])} attachments:")
    
    Enum.each(message["attachments"], fn attachment ->
      IO.puts("  - #{attachment["type"]}: #{attachment["url"]}")
    end)
  end
end)
```

### Rate Limit Management

```elixir
# Be aware of rate limits when sending messages
defmodule MessageSender do
  @reservation_rate_limit 2    # 2 messages per minute per reservation
  @global_rate_limit 50        # 50 messages per 5 minutes globally
  
  def send_with_rate_limiting(client, reservation_uuid, message_opts) do
    # Implement your own rate limiting logic here
    case HospitableClient.send_message(client, reservation_uuid, message_opts) do
      {:ok, response} ->
        IO.puts("Message sent successfully: #{response["data"]["sent_reference_id"]}")
        {:ok, response}
        
      {:error, {:http_error, 429, _}} ->
        IO.puts("Rate limit exceeded, please wait before sending more messages")
        {:error, :rate_limited}
        
      {:error, reason} ->
        IO.puts("Failed to send message: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  def send_multiple_messages(client, reservation_uuid, messages) do
    # Send messages with delays to respect rate limits
    Enum.reduce_while(messages, [], fn message_body, sent_messages ->
      case send_with_rate_limiting(client, reservation_uuid, body: message_body) do
        {:ok, response} ->
          # Wait 30 seconds between messages to respect rate limit
          Process.sleep(30_000)
          {:cont, [response | sent_messages]}
          
        {:error, :rate_limited} ->
          # Stop sending if rate limited
          {:halt, sent_messages}
          
        {:error, _reason} ->
          # Continue with next message if individual message fails
          {:cont, sent_messages}
      end
    end)
  end
end

# Usage
messages_to_send = [
  "Welcome to our property!",
  "Check-in instructions will be sent 24 hours before arrival.",
  "Please let us know if you have any questions."
]

MessageSender.send_multiple_messages(client, reservation_uuid, messages_to_send)
```

## Interactive Shell Usage

Here are practical examples of using the API directly in an Elixir shell (`iex -S mix`):

### Setup and Authentication

```elixir
# Start the shell with your project
# $ iex -S mix

# Set your API key (choose one method)
System.put_env("HOSPITABLE_API_KEY", "your-api-key-here")
# OR
Application.put_env(:ex_hospitable, :api_key, "your-api-key-here")

# Create a client
{:ok, client} = HospitableClient.from_env()
# => {:ok, %{api_key: "your-api-key-here", base_url: "https://public.api.hospitable.com"}}

# Or create directly with key
client = HospitableClient.new("your-api-key-here")
```

### Basic Reservation Queries

```elixir
# Get recent reservations for your properties (required parameter)
property_ids = ["your-property-uuid-1", "your-property-uuid-2"]

{:ok, response} = HospitableClient.get_reservations(client, properties: property_ids)
# => {:ok, %{"data" => [...], "links" => {...}, "meta" => {...}}}

# Check how many reservations you got
length(response["data"])
# => 10

# Get more results per page
{:ok, response} = HospitableClient.get_reservations(client, 
  properties: property_ids, 
  per_page: 50
)
```

### Working with Dates and Filtering

```elixir
# Get reservations for a specific date range
{:ok, response} = HospitableClient.get_reservations(client,
  properties: property_ids,
  start_date: "2024-01-01",
  end_date: "2024-01-31"
)

# Get today's check-ins
today = Date.utc_today() |> Date.to_string()
{:ok, checkins} = HospitableClient.get_reservations(client,
  properties: property_ids,
  date_query: "checkin",
  start_date: today,
  end_date: today
)

# Get next week's check-outs
next_week = Date.utc_today() |> Date.add(7) |> Date.to_string()
{:ok, checkouts} = HospitableClient.get_reservations(client,
  properties: property_ids,
  date_query: "checkout", 
  start_date: today,
  end_date: next_week
)
```

### Including Additional Data

```elixir
# Get reservations with guest information
{:ok, response} = HospitableClient.get_reservations(client,
  properties: property_ids,
  include: "guest"
)

# Check the first guest's details
first_reservation = List.first(response["data"])
guest = first_reservation["guest"]
guest["first_name"]  # => "John"
guest["email"]       # => "john@example.com"

# Get full details including financials
{:ok, response} = HospitableClient.get_reservations(client,
  properties: property_ids,
  include: "guest,financials,properties"
)

# Check financial details
first_reservation = List.first(response["data"])
financials = first_reservation["financials"]
guest_total = get_in(financials, ["guest", "total_price", "formatted"])
host_revenue = get_in(financials, ["host", "revenue", "formatted"])
```

### Finding Specific Reservations

```elixir
# Find by platform ID (e.g., Airbnb confirmation code)
{:ok, response} = HospitableClient.get_reservations(client,
  properties: property_ids,
  platform_id: "HM123456789"
)

# Get a specific reservation by UUID
reservation_uuid = "6f58fd0a-a9cb-3746-9219-384a156ff7bb"
{:ok, response} = HospitableClient.get_reservation(client, reservation_uuid)
reservation = response["data"]

# Get reservation with all details
{:ok, response} = HospitableClient.get_reservation(client, reservation_uuid,
  include: "guest,financials,properties,review"
)
```

### Working with Reservation Status

```elixir
# Get some reservations to work with
{:ok, response} = HospitableClient.get_reservations(client, properties: property_ids)
reservations = response["data"]

# Check status of first reservation
first_reservation = List.first(reservations)
HospitableClient.Reservations.confirmed?(first_reservation)
# => true

# Find all reservations that need action
alias HospitableClient.Reservations
needs_attention = Enum.filter(reservations, &Reservations.needs_action?/1)
length(needs_attention)
# => 3

# Check cancellation status
cancelled_reservations = Enum.filter(reservations, &Reservations.cancelled?/1)
Enum.map(cancelled_reservations, &Reservations.cancellation_reason/1)
# => ["declined", "withdrawn", "expired"]
```

### Exploring Reservation Data Structure

```elixir
# Get a reservation to explore
{:ok, response} = HospitableClient.get_reservation(client, 
  "your-reservation-uuid", 
  include: "guest,financials,properties"
)
reservation = response["data"]

# Explore the reservation structure
reservation |> Map.keys() |> Enum.sort()
# => ["arrival_date", "booking_date", "check_in", "check_out", ...]

# Check reservation details
reservation["platform"]           # => "airbnb"
reservation["nights"]             # => 3
reservation["arrival_date"]       # => "2024-03-15 15:00:00"
reservation["departure_date"]     # => "2024-03-18 11:00:00"

# Guest information
guest = reservation["guest"]
"#{guest["first_name"]} #{guest["last_name"]}"  # => "John Doe"

# Property information  
property = List.first(reservation["properties"])
property["public_name"]  # => "Cozy Downtown Apartment"

# Financial breakdown
financials = reservation["financials"]
get_in(financials, ["guest", "total_price", "formatted"])  # => "$450.00"
get_in(financials, ["host", "revenue", "formatted"])       # => "$382.50"
```

### Working with Properties

```elixir
# Get all properties
{:ok, response} = HospitableClient.get_properties(client)
properties = response["data"]

# Get properties with full details
{:ok, response} = HospitableClient.get_properties(client,
  include: "user,listings,details,bookings"
)

# Search for available properties
{:ok, results} = HospitableClient.search_properties(client,
  adults: 2,
  start_date: "2024-08-16",
  end_date: "2024-08-21"
)

# Check property attributes
first_property = List.first(properties)
HospitableClient.Properties.pet_friendly?(first_property)  # => true
HospitableClient.Properties.max_guests(first_property)     # => 4

# For search results, check availability
search_results = results["data"]
first_result = List.first(search_results)
HospitableClient.Properties.available?(first_result)      # => true
```

### Pagination and Bulk Operations

```elixir
# Get all reservations across multiple pages
defmodule ReservationFetcher do
  def get_all_reservations(client, property_ids, page \\ 1, acc \\ []) do
    case HospitableClient.get_reservations(client, 
           properties: property_ids, 
           page: page, 
           per_page: 100) do
      {:ok, response} ->
        new_reservations = response["data"]
        all_reservations = acc ++ new_reservations
        
        # Check if there are more pages
        if response["meta"]["current_page"] < response["meta"]["last_page"] do
          get_all_reservations(client, property_ids, page + 1, all_reservations)
        else
          all_reservations
        end
      
      {:error, reason} ->
        {:error, reason}
    end
  end
end

# Use the helper
all_reservations = ReservationFetcher.get_all_reservations(client, property_ids)
length(all_reservations)  # => 245

# Quick analysis of all reservations
confirmed_count = Enum.count(all_reservations, &Reservations.confirmed?/1)
pending_count = Enum.count(all_reservations, &Reservations.needs_action?/1)
cancelled_count = Enum.count(all_reservations, &Reservations.cancelled?/1)

IO.puts("Confirmed: #{confirmed_count}, Pending: #{pending_count}, Cancelled: #{cancelled_count}")
```

### Working with Messages in Interactive Shell

```elixir
# Get messages for a reservation
reservation_uuid = "becd1474-ccd1-40bf-9ce8-04456bfa338d"

{:ok, response} = HospitableClient.get_messages(client, reservation_uuid)
messages = response["data"]

# Explore message structure
first_message = List.first(messages)
first_message |> Map.keys() |> Enum.sort()
# => ["attachments", "body", "content_type", "conversation_id", ...]

# Check sender information
first_message["sender"]["full_name"]    # => "Jane Doe"
first_message["sender_type"]            # => "host" or "guest"

# Look for messages with attachments
messages_with_images = Enum.filter(messages, fn msg ->
  length(msg["attachments"]) > 0
end)

# Send a quick message
{:ok, response} = HospitableClient.send_message(client, reservation_uuid,
  body: "Thanks for your message! We'll get back to you soon."
)

response["data"]["sent_reference_id"]
# => "2d637b98-2e20-470e-a582-83c4304d48a8"

# Send message with images
{:ok, response} = HospitableClient.send_message(client, reservation_uuid,
  body: "Here's the property information you requested:",
  images: ["https://example.com/property-guide.jpg"]
)
```

### Error Handling Examples

```elixir
# Handle missing property ID error
try do
  HospitableClient.get_reservations(client, [])
rescue
  ArgumentError -> IO.puts("Properties parameter is required!")
end

# Handle API errors gracefully
case HospitableClient.get_reservation(client, "invalid-uuid") do
  {:ok, response} -> 
    IO.puts("Found reservation!")
  {:error, {:http_error, 404, _}} -> 
    IO.puts("Reservation not found")
  {:error, {:http_error, 401, _}} -> 
    IO.puts("Authentication failed - check your API key")
  {:error, reason} -> 
    IO.puts("Other error: #{inspect(reason)}")
end

# Handle message sending errors
case HospitableClient.send_message(client, "invalid-uuid", body: "Test") do
  {:ok, response} ->
    IO.puts("Message sent successfully!")
  {:error, {:http_error, 404, _}} ->
    IO.puts("Reservation not found")
  {:error, {:http_error, 429, _}} ->
    IO.puts("Rate limit exceeded - please wait before sending more messages")
  {:error, {:http_error, 401, _}} ->
    IO.puts("Authentication failed - check your API key and scopes")
  {:error, reason} ->
    IO.puts("Message sending failed: #{inspect(reason)}")
end

# Handle missing message body
try do
  HospitableClient.send_message(client, "reservation-uuid", images: ["test.jpg"])
rescue
  ArgumentError -> IO.puts("Message body is required!")
end
```