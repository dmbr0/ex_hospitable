# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-08-17

### Added
- Initial release of HospitableClient
- Personal Access Token (PAT) authentication support
- Centralized authentication state management with GenServer
- HTTP client with full REST API support (GET, POST, PUT, PATCH, DELETE)
- Environment-based configuration with .env file support
- Comprehensive error handling and structured error responses
- Periodic token validation
- Automatic JSON encoding/decoding
- Configurable timeouts and HTTP options
- Complete test suite
- Documentation with examples

### Features
- `HospitableClient` main module with public API
- `HospitableClient.Auth.Manager` GenServer for authentication management
- `HospitableClient.HTTP.Client` for HTTP requests
- Erlang records for type safety and data structure consistency
- Supervisor tree for fault tolerance
- Environment variable configuration
- Comprehensive logging

### Dependencies
- HTTPoison for HTTP requests
- Jason for JSON encoding/decoding
- Dotenv for environment variable loading
- ExDoc for documentation
- Credo for code analysis
- Dialyxir for type checking
