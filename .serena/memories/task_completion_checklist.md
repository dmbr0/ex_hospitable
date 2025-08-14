# Task Completion Checklist

## Before Submitting Code Changes

### Code Quality
- [ ] Run `mix format` to ensure consistent formatting
- [ ] Run `mix compile` to verify compilation without warnings
- [ ] Add/update `@doc` documentation for new/modified functions
- [ ] Add/update `@spec` type annotations for public functions
- [ ] Include usage examples in documentation

### Testing
- [ ] Run `mix test` to ensure all tests pass
- [ ] Add doctests for new functions with examples
- [ ] Write unit tests for complex logic
- [ ] Verify error handling paths are tested

### Type Safety
- [ ] Define appropriate `@type` specifications for new data structures
- [ ] Ensure function specs match implementation
- [ ] Validate input parameters with clear error messages

### API Consistency
- [ ] Follow existing error tuple patterns `{:ok, result}` | `{:error, reason}`
- [ ] Use consistent parameter ordering (config first, options second)
- [ ] Include comprehensive type definitions for complex responses

### Documentation
- [ ] Update module `@moduledoc` if adding new functionality
- [ ] Include real-world usage examples
- [ ] Update README.md if adding new API endpoints
- [ ] Verify examples in documentation are accurate

### Final Verification
- [ ] Test interactive examples in `iex -S mix`
- [ ] Verify all HTTP endpoints return expected response structures
- [ ] Check that error handling covers network failures and API errors