# Integration Test Projects

This directory contains sample Rust WebAssembly projects for integration testing.

## Test Projects

### hello-wasm
A minimal Rust WASM project that demonstrates basic functionality and should trigger some security queries.

### complex-wasm-app  
A more complex project with JavaScript interop that tests performance and best practice queries.

## Running Integration Tests

```bash
# Run against a sample project
./integration-test.sh hello-wasm

# Run against all test projects
./integration-test.sh --all

# Generate test databases for manual testing
./integration-test.sh --setup-only
```

## Adding New Test Projects

1. Create a new directory under `integration/`
2. Add a realistic Rust WASM project with `Cargo.toml`
3. Include JavaScript files that interact with the WASM
4. Add expected results in `{project-name}.expected.json`
5. Update the integration test script