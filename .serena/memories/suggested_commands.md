# Suggested Commands for Ex Hospitable Development

## Core Development Commands

### Testing
- `mix test` - Run all tests including doctests
- `mix test test/hospitable_client_test.exs` - Run specific test file
- `mix test --verbose` - Run tests with detailed output

### Compilation
- `mix compile` - Compile the project
- `mix deps.get` - Fetch dependencies 
- `mix deps.compile` - Compile dependencies
- `mix clean` - Clean compiled files

### Interactive Development
- `iex -S mix` - Start IEx with the project loaded for interactive testing
- `mix run -e "expression"` - Run Elixir expression with project loaded

### Code Quality
- `mix format` - Format code according to .formatter.exs
- `mix format --check-formatted` - Check if code is properly formatted
- `mix dialyzer` - Static analysis (if dialyzer is added to deps)
- `mix credo` - Code analysis (if credo is added to deps)

### Documentation
- `mix docs` - Generate documentation with ExDoc
- `mix hex.docs open` - Open generated docs in browser

### Hex Package Management
- `mix hex.build` - Build package for Hex
- `mix hex.publish` - Publish to Hex (when ready)

## System Commands (Linux)
- `ls -la` - List files with details
- `grep -r "pattern" lib/` - Search for patterns in code
- `find . -name "*.ex" | xargs grep "pattern"` - Find patterns in Elixir files
- `git status` - Check git status
- `git diff` - Show changes