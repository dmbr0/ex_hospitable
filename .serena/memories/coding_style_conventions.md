# Coding Style and Conventions

## Elixir Style Guidelines

### Module Documentation
- All modules include comprehensive `@moduledoc` with description and usage examples
- Individual functions documented with `@doc` including parameters, examples, and return types
- Extensive use of doctests for validation and examples

### Type Specifications
- Comprehensive `@type` definitions for complex data structures
- `@spec` annotations for all public functions
- Clear type hierarchies (e.g., property, search_result, config types)

### Function Organization
- Public API functions first, followed by private helpers
- Clear separation between core functionality and utility functions
- Consistent parameter ordering (config first, then options)

### Error Handling
- Consistent error tuple patterns: `{:ok, result}` | `{:error, reason}`
- Structured error types: `{:json_decode_error, reason}`, `{:http_error, status, body}`
- Input validation with meaningful error messages

### Code Structure
- Use of module attributes for constants (`@base_url`)
- Private helper functions grouped at module end
- Clear separation of concerns between modules

### Formatting
- Uses `mix format` with standard Elixir formatter settings
- Configured in `.formatter.exs` to format `{mix,.formatter}.exs`, `{config,lib,test}/**/*.{ex,exs}`
- Consistent indentation and line length

### Documentation Examples
- All public functions include usage examples
- Examples show both successful and error cases where relevant
- Interactive shell examples demonstrate real-world usage patterns