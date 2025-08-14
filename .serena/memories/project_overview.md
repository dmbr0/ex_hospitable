# Ex Hospitable - Project Overview

## Purpose
An Elixir client library for the Hospitable API, providing comprehensive access to reservations, properties, and messaging endpoints. This library enables developers to interact with Hospitable's short-term rental management platform programmatically.

## Tech Stack
- **Language**: Elixir 1.18+
- **Build Tool**: Mix
- **HTTP Client**: HTTPoison ~> 2.0
- **JSON**: Jason ~> 1.4
- **Documentation**: ExDoc ~> 0.31 (dev only)

## Project Structure
- `lib/hospitable_client.ex` - Main client module with core configuration
- `lib/hospitable_client/properties.ex` - Properties API with get_properties and search_properties
- `lib/hospitable_client/reservations.ex` - Reservations API functionality
- `lib/hospitable_client/messages.ex` - Messages API for reservation communication
- `lib/hospitable_client/auth.ex` - Authentication and header generation
- `lib/hospitable_client/config.ex` - Client configuration management
- `test/` - Test suite with doctests enabled
- `mix.exs` - Project configuration and dependencies

## Key Features
- Multiple authentication methods (direct API key, environment config)
- Comprehensive type specifications with @type definitions
- Extensive documentation with examples and doctests
- Error handling for HTTP requests and JSON parsing
- Built-in validation for search parameters and dates
- Helper functions for property rules, capacity, and availability checks