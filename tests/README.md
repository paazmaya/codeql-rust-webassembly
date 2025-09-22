# Testing the Rust WebAssembly CodeQL Pack

This directory contains comprehensive tests for the CodeQL pack to ensure queries work correctly and produce expected results.

## Test Structure

```
tests/
├── test-data/           # Sample code that should trigger queries
│   ├── rust-src/        # Rust WASM code with security issues
│   └── js-src/          # JavaScript code with WASM interaction issues
├── query-tests/         # Expected results for each query
│   ├── UnsafeWasmCode.expected
│   ├── MissingWasmInputValidation.expected
│   └── ...
├── integration/         # Real-world sample projects
│   └── hello-wasm/      # Complete Rust WASM project
├── run-tests.sh        # Bash test runner
├── test-runner.py      # Python test runner (cross-platform)
└── README.md           # This file
```

## Running Tests

### Quick Test (Validation Only)
```bash
# Using Python runner (recommended)
python tests/test-runner.py --validate

# Using bash runner
./tests/run-tests.sh --validate
```

### Full Test Suite
```bash
# Run all tests
python tests/test-runner.py

# Or with bash
./tests/run-tests.sh
```

### Individual Query Tests
```bash
# Test a specific query
codeql query run queries/security/UnsafeWasmCode.ql \
    --database=tests/test-databases/rust-test-db
```

## Test Types

### 1. Pack Validation Tests
- Validates `qlpack.yml` syntax and dependencies
- Checks query syntax and formatting
- Ensures pack can be installed

### 2. Unit Tests for Queries
- Tests each query against known test cases
- Compares actual results with expected results
- Validates that queries find the intended issues

### 3. Query Suite Tests
- Tests that query suites execute correctly
- Validates suite configuration files
- Ensures suites work with appropriate databases

### 4. Integration Tests
- Tests against realistic Rust WASM projects
- Validates end-to-end analysis workflows
- Checks for false positives/negatives

## Writing New Tests

### Adding Test Cases
1. Add problematic code to `test-data/rust-src/` or `test-data/js-src/`
2. Run the query manually to see actual results:
   ```bash
   codeql query run queries/security/YourQuery.ql --database=test-db
   ```
3. Create/update the `.expected` file with results
4. Run the test suite to verify

### Adding New Queries
1. Create the query in the appropriate `queries/` subdirectory
2. Add test cases that should trigger the query
3. Create an `.expected` file with expected results
4. Update query suites if appropriate
5. Run tests to validate

### Expected Results Format
Expected files should contain CodeQL results in the format:
```
| file:line:col:line:col | message |
```

Example:
```
| tests/test-data/rust-src/lib.rs:5:5:9:6 | Unsafe code block in WebAssembly-exported function may lead to memory safety issues |
```

## Continuous Integration

The test suite is designed to run in CI environments:

```bash
# CI-friendly run (exits with proper codes)
python tests/test-runner.py
echo "Exit code: $?"
```

## Test Database Management

Test databases are automatically created from the sample code. To manually manage:

```bash
# Clean test databases
./tests/run-tests.sh --clean

# Create databases only
codeql database create --language=rust --source-root=tests/test-data/rust-src tests/rust-db
codeql database create --language=javascript --source-root=tests/test-data/js-src tests/js-db
```

## Troubleshooting

### Query Compilation Errors
- Check that imports are correct (`import rust` vs `import javascript`)
- Ensure CodeQL libraries are properly installed
- Validate query syntax with `codeql query format`

### Test Failures
- Compare expected vs actual results carefully
- Check if the test data actually contains the pattern the query looks for
- Verify the query logic matches the test case

### Database Creation Issues
- Ensure the source code compiles (for Rust)
- Check that required dependencies are available
- For JavaScript, ensure files have proper extensions

## Performance Considerations

- Test databases are small but queries should still be efficient
- Large test data files should be avoided
- Use `--max-disk-cache` if running many tests

## Contributing Tests

When contributing new queries or test cases:

1. **Test Coverage**: Ensure both positive and negative test cases
2. **Documentation**: Update expected results and this README
3. **Validation**: Run the full test suite before submitting
4. **Realistic Examples**: Use patterns from real Rust WASM projects