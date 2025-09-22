# Contributing to Rust WebAssembly CodeQL Pack

## Query Development Guidelines

### File Structure
```
queries/
├── security/          # Security-related queries
├── performance/       # Performance optimization queries
└── best-practices/    # Code quality and maintainability
```

### Query Categories

#### Security Queries
Focus on:
- Memory safety violations at WASM boundaries
- Input validation between JS and Rust
- Unsafe code patterns in WASM exports
- XSS vulnerabilities in WASM-powered apps

#### Performance Queries  
Focus on:
- Inefficient data transfers between JS and WASM
- Memory allocation patterns
- Bundle size optimizations
- Unnecessary serialization/deserialization

#### Best Practices
Focus on:
- Error handling patterns
- Type safety in bindings
- Modern WebAssembly API usage
- Code maintainability

### Writing Quality Queries

1. **Metadata Requirements**
   - Clear `@name` and `@description`
   - Appropriate `@severity` and `@precision`
   - Relevant `@tags`
   - Unique `@id` following pattern: `{lang}-wasm/{query-name}`

2. **Code Quality**
   - Use specific predicates over broad patterns
   - Include helpful error messages with context
   - Test against real-world Rust WASM projects

3. **Performance**
   - Avoid expensive operations in query loops
   - Use appropriate indexing
   - Test query execution time

### Testing Queries

```bash
# Test individual query
codeql query run queries/security/UnsafeWasmCode.ql --database=/path/to/test-db

# Test query suite
codeql database analyze test-db query-suites/security-suite.yml
```

### Submission Process

1. Create queries in appropriate category directory
2. Add query to relevant suite files
3. Test against sample projects
4. Update documentation if needed
5. Submit pull request with test results