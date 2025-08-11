# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Elixir project named `ex_hospitable` (version 0.1.0) that appears to be a client library for Hospitable services. The project follows standard Elixir/Mix conventions and is currently in its initial development phase with minimal implementation.

## Commands

### Development Commands
- `mix compile` - Compile the project
- `mix test` - Run all tests
- `mix test test/hospitable_client_test.exs` - Run a specific test file
- `mix deps.get` - Fetch dependencies (when added)
- `mix deps.compile` - Compile dependencies

### Interactive Development
- `iex -S mix` - Start IEx with the project loaded for interactive development

## Architecture

### Project Structure
- `lib/hospitable_client.ex` - Main module containing the core client functionality
- `test/hospitable_client_test.exs` - Test suite with doctests enabled
- `mix.exs` - Project configuration and dependencies

### Key Design Patterns
- Uses standard Elixir module structure with `@moduledoc` and `@doc` documentation
- Includes doctests in the test suite via `doctest HospitableClient`
- Currently implements a minimal "hello world" pattern that should be replaced with actual client functionality

## Development Notes

- Elixir version requirement: ~> 1.18
- No external dependencies currently defined
- Logger is available as an extra application
- Project is set up for Hex package publishing but description needs to be added