# Rust WebAssembly CodeQL Pack

A CodeQL pack for analyzing Rust WebAssembly projects with web technologies (HTML, JavaScript, TypeScript).

## Quick Start

```bash
# Install the pack
codeql pack install paazmaya/rust-webassembly

# Run analysis on your project
codeql database create --language=rust,javascript,html my-db /path/to/your/project
codeql database analyze my-db paazmaya/rust-webassembly --format=sarif-latest --output=results.sarif
```

## What This Pack Analyzes

- **Rust code** compiled to WebAssembly
- **JavaScript/TypeScript** interfacing with WASM
- **HTML** loading and using WebAssembly modules
- **Cross-language security issues** between Rust and JS

## Query Categories

### Security
- Memory safety violations in Rust WASM
- Unsafe JavaScript-WASM boundaries  
- XSS vulnerabilities in WASM-powered web apps
- Data validation at language boundaries

### Performance
- Inefficient WASM-JS data transfers
- Suboptimal memory management
- Bundle size optimization opportunities

### Best Practices
- Proper error handling across language boundaries
- Type safety in WASM bindings
- Modern WebAssembly API usage

## Usage Patterns

```bash
# Security-focused analysis
codeql database analyze my-db paazmaya/rust-webassembly:security-suite

# Performance analysis
codeql database analyze my-db paazmaya/rust-webassembly:performance-suite

# Full analysis
codeql database analyze my-db paazmaya/rust-webassembly:all-queries
```

## Testing

```bash
# Validate pack and query syntax
python tests/test-runner.py --validate

# Run full test suite
python tests/test-runner.py

# Alternative bash runner
./tests/run-tests.sh
```

Tests validate query logic against sample Rust WASM and JavaScript code. See [tests/README.md](./tests/README.md) for details.

## Documentation Links

### CodeQL Resources
- [CodeQL Documentation](https://codeql.github.com/)
- [Writing CodeQL Queries](https://codeql.github.com/docs/writing-codeql-queries/)
- [CodeQL for Rust](https://codeql.github.com/docs/codeql-language-guides/codeql-for-rust/)
- [CodeQL for JavaScript](https://codeql.github.com/docs/codeql-language-guides/codeql-for-javascript/)

### Rust WebAssembly Resources
- [Rust and WebAssembly Book](https://rustwasm.github.io/docs/book/)
- [wasm-bindgen Guide](https://rustwasm.github.io/wasm-bindgen/)
- [wasm-pack Documentation](https://rustwasm.github.io/wasm-pack/)
- [WebAssembly MDN](https://developer.mozilla.org/en-US/docs/WebAssembly)

### Security Resources
- [WebAssembly Security](https://webassembly.org/docs/security/)
- [OWASP WebAssembly Security](https://cheatsheetseries.owasp.org/cheatsheets/WebAssembly_Security_Cheat_Sheet.html)
- [Rust Security Guidelines](https://anssi-fr.github.io/rust-guide/)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for query development guidelines.

## License

MIT - See [LICENSE](./LICENSE) file.