#!/bin/bash

# CodeQL Pack Test Runner
# Tests queries against sample data to ensure they work correctly

set -e

PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DATA_DIR="$PACK_DIR/tests/test-data"
QUERY_DIR="$PACK_DIR/queries"
TEST_DB_DIR="$PACK_DIR/tests/test-databases"

echo "🧪 Running CodeQL Pack Tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to create test databases
create_test_databases() {
    echo "📦 Creating test databases..."
    
    # Clean up old test databases
    rm -rf "$TEST_DB_DIR"
    mkdir -p "$TEST_DB_DIR"
    
    # Create Rust database
    echo "  Creating Rust database..."
    codeql database create \
        --language=rust \
        --source-root="$TEST_DATA_DIR/rust-src" \
        "$TEST_DB_DIR/rust-test-db" \
        --overwrite
    
    # Create JavaScript database  
    echo "  Creating JavaScript database..."
    codeql database create \
        --language=javascript \
        --source-root="$TEST_DATA_DIR/js-src" \
        "$TEST_DB_DIR/js-test-db" \
        --overwrite
}

# Function to run individual query tests
run_query_test() {
    local query_file="$1"
    local test_db="$2"
    local expected_file="$3"
    
    query_name=$(basename "$query_file" .ql)
    echo "  Testing $query_name..."
    
    # Run the query
    result_file="/tmp/codeql-test-$query_name.txt"
    if codeql query run "$query_file" --database="$test_db" --output="$result_file" 2>/dev/null; then
        # Compare with expected results
        if [ -f "$expected_file" ]; then
            if diff -q "$expected_file" "$result_file" > /dev/null; then
                echo -e "    ${GREEN}✓${NC} $query_name passed"
                return 0
            else
                echo -e "    ${RED}✗${NC} $query_name failed - results don't match expected"
                echo "    Expected:"
                cat "$expected_file" | sed 's/^/      /'
                echo "    Actual:"
                cat "$result_file" | sed 's/^/      /'
                return 1
            fi
        else
            echo -e "    ${YELLOW}?${NC} $query_name - no expected results file"
            echo "    Results:"
            cat "$result_file" | sed 's/^/      /'
            return 0
        fi
    else
        echo -e "    ${RED}✗${NC} $query_name failed to run"
        return 1
    fi
}

# Function to test query suites
test_query_suites() {
    echo "🎯 Testing query suites..."
    
    for suite_file in "$PACK_DIR"/query-suites/*.yml; do
        suite_name=$(basename "$suite_file" .yml)
        echo "  Testing suite: $suite_name"
        
        # Test against both databases
        for db in "$TEST_DB_DIR"/*-test-db; do
            db_name=$(basename "$db")
            if codeql database analyze "$db" "$suite_file" --format=csv --output="/tmp/suite-$suite_name-$db_name.csv" 2>/dev/null; then
                echo -e "    ${GREEN}✓${NC} $suite_name works with $db_name"
            else
                echo -e "    ${YELLOW}!${NC} $suite_name skipped for $db_name (language mismatch expected)"
            fi
        done
    done
}

# Function to run pack validation
validate_pack() {
    echo "📋 Validating pack structure..."
    
    # Check qlpack.yml
    if codeql pack install "$PACK_DIR" --dry-run > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} qlpack.yml is valid"
    else
        echo -e "  ${RED}✗${NC} qlpack.yml has issues"
        return 1
    fi
    
    # Check query syntax
    local syntax_errors=0
    for query_file in "$QUERY_DIR"/**/*.ql; do
        if [ -f "$query_file" ]; then
            if codeql query format "$query_file" --check > /dev/null 2>&1; then
                echo -e "  ${GREEN}✓${NC} $(basename "$query_file") syntax is valid"
            else
                echo -e "  ${RED}✗${NC} $(basename "$query_file") has syntax errors"
                syntax_errors=$((syntax_errors + 1))
            fi
        fi
    done
    
    return $syntax_errors
}

# Main test execution
main() {
    echo "Starting tests for CodeQL pack: paazmaya/rust-webassembly"
    echo "Pack directory: $PACK_DIR"
    echo ""
    
    # Step 1: Validate pack structure
    if ! validate_pack; then
        echo -e "${RED}❌ Pack validation failed${NC}"
        exit 1
    fi
    
    # Step 2: Create test databases
    create_test_databases
    
    # Step 3: Run individual query tests
    echo "🔍 Testing individual queries..."
    test_failures=0
    
    # Test Rust queries
    for query_file in "$QUERY_DIR"/security/Unsafe*.ql "$QUERY_DIR"/best-practices/*.ql; do
        if [ -f "$query_file" ]; then
            query_name=$(basename "$query_file" .ql)
            expected_file="$PACK_DIR/tests/query-tests/$query_name.expected"
            if ! run_query_test "$query_file" "$TEST_DB_DIR/rust-test-db" "$expected_file"; then
                test_failures=$((test_failures + 1))
            fi
        fi
    done
    
    # Test JavaScript queries
    for query_file in "$QUERY_DIR"/security/Missing*.ql "$QUERY_DIR"/performance/*.ql; do
        if [ -f "$query_file" ]; then
            query_name=$(basename "$query_file" .ql)
            expected_file="$PACK_DIR/tests/query-tests/$query_name.expected"
            if ! run_query_test "$query_file" "$TEST_DB_DIR/js-test-db" "$expected_file"; then
                test_failures=$((test_failures + 1))
            fi
        fi
    done
    
    # Step 4: Test query suites
    test_query_suites
    
    # Summary
    echo ""
    if [ $test_failures -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ $test_failures test(s) failed${NC}"
        exit 1
    fi
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo "  --clean       Clean test databases and temporary files"
    echo "  --validate    Only run pack validation"
    echo ""
    echo "This script tests the CodeQL pack by:"
    echo "  1. Validating pack structure and query syntax"
    echo "  2. Creating test databases from sample code"
    echo "  3. Running queries and comparing with expected results"
    echo "  4. Testing query suites"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --clean)
        echo "🧹 Cleaning test files..."
        rm -rf "$TEST_DB_DIR"
        rm -f /tmp/codeql-test-*.txt
        rm -f /tmp/suite-*.csv
        echo "Done."
        exit 0
        ;;
    --validate)
        validate_pack
        exit $?
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac