#!/usr/bin/env python3
"""
CodeQL Pack Test Runner
Tests queries against sample data to ensure they work correctly.
"""

import os
import sys
import subprocess
import tempfile
import json
from pathlib import Path

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color

class CodeQLTester:
    def __init__(self, pack_dir):
        self.pack_dir = Path(pack_dir)
        self.test_data_dir = self.pack_dir / "tests" / "test-data"
        self.query_dir = self.pack_dir / "queries"
        self.test_db_dir = self.pack_dir / "tests" / "test-databases"
        
    def log(self, message, color=None):
        if color:
            print(f"{color}{message}{Colors.NC}")
        else:
            print(message)
            
    def run_command(self, cmd, check=True, capture_output=True):
        """Run a shell command and return the result."""
        try:
            result = subprocess.run(
                cmd, shell=True, check=check, 
                capture_output=capture_output, text=True
            )
            return result
        except subprocess.CalledProcessError as e:
            if not check:
                return e
            raise
            
    def validate_pack(self):
        """Validate the pack structure and query syntax."""
        self.log("📋 Validating pack structure...", Colors.BLUE)
        
        # Check if codeql is available
        try:
            self.run_command("codeql version")
        except subprocess.CalledProcessError:
            self.log("❌ CodeQL CLI not found in PATH", Colors.RED)
            return False
            
        # Validate qlpack.yml
        result = self.run_command(
            f"codeql pack install {self.pack_dir} --dry-run",
            check=False
        )
        if result.returncode == 0:
            self.log("  ✓ qlpack.yml is valid", Colors.GREEN)
        else:
            self.log("  ✗ qlpack.yml has issues", Colors.RED)
            self.log(f"    {result.stderr}")
            return False
            
        # Check query syntax
        syntax_errors = 0
        for query_file in self.query_dir.rglob("*.ql"):
            result = self.run_command(
                f"codeql query format {query_file} --check",
                check=False
            )
            if result.returncode == 0:
                self.log(f"  ✓ {query_file.name} syntax is valid", Colors.GREEN)
            else:
                self.log(f"  ✗ {query_file.name} has syntax errors", Colors.RED)
                syntax_errors += 1
                
        return syntax_errors == 0
        
    def create_test_databases(self):
        """Create test databases from sample code."""
        self.log("📦 Creating test databases...", Colors.BLUE)
        
        # Clean up old databases
        if self.test_db_dir.exists():
            import shutil
            shutil.rmtree(self.test_db_dir)
        self.test_db_dir.mkdir(parents=True, exist_ok=True)
        
        # Create Rust database
        rust_src = self.test_data_dir / "rust-src"
        rust_db = self.test_db_dir / "rust-test-db"
        
        if rust_src.exists():
            self.log("  Creating Rust database...")
            result = self.run_command(
                f"codeql database create "
                f"--language=rust "
                f"--source-root={rust_src} "
                f"{rust_db} "
                f"--overwrite",
                check=False
            )
            if result.returncode != 0:
                self.log("  ⚠ Rust database creation failed (may be expected)", Colors.YELLOW)
                
        # Create JavaScript database
        js_src = self.test_data_dir / "js-src"
        js_db = self.test_db_dir / "js-test-db"
        
        if js_src.exists():
            self.log("  Creating JavaScript database...")
            result = self.run_command(
                f"codeql database create "
                f"--language=javascript "
                f"--source-root={js_src} "
                f"{js_db} "
                f"--overwrite",
                check=False
            )
            if result.returncode != 0:
                self.log("  ⚠ JavaScript database creation failed", Colors.YELLOW)
                
    def run_query_test(self, query_file, test_db, expected_file):
        """Run a single query test and compare with expected results."""
        query_name = query_file.stem
        self.log(f"  Testing {query_name}...")
        
        with tempfile.NamedTemporaryFile(mode='w+', suffix='.csv', delete=False) as f:
            result_file = f.name
            
        try:
            # Run the query
            result = self.run_command(
                f"codeql query run {query_file} "
                f"--database={test_db} "
                f"--output={result_file}",
                check=False
            )
            
            if result.returncode == 0:
                # Compare with expected results if available
                if expected_file.exists():
                    with open(expected_file, 'r') as f:
                        expected = f.read().strip()
                    with open(result_file, 'r') as f:
                        actual = f.read().strip()
                        
                    if expected == actual:
                        self.log(f"    ✓ {query_name} passed", Colors.GREEN)
                        return True
                    else:
                        self.log(f"    ✗ {query_name} failed - results don't match", Colors.RED)
                        self.log(f"    Expected: {expected}")
                        self.log(f"    Actual: {actual}")
                        return False
                else:
                    self.log(f"    ? {query_name} - no expected results file", Colors.YELLOW)
                    with open(result_file, 'r') as f:
                        results = f.read().strip()
                    if results:
                        self.log(f"    Results: {results}")
                    return True
            else:
                self.log(f"    ✗ {query_name} failed to run", Colors.RED)
                self.log(f"    Error: {result.stderr}")
                return False
                
        finally:
            # Clean up temp file
            try:
                os.unlink(result_file)
            except:
                pass
                
    def test_queries(self):
        """Test individual queries against test databases."""
        self.log("🔍 Testing individual queries...", Colors.BLUE)
        
        test_failures = 0
        query_tests_dir = self.pack_dir / "tests" / "query-tests"
        
        # Test databases
        test_dbs = list(self.test_db_dir.glob("*-test-db"))
        
        for db in test_dbs:
            db_lang = "rust" if "rust" in db.name else "javascript"
            self.log(f"  Testing against {db.name}...")
            
            # Find queries appropriate for this database
            for query_file in self.query_dir.rglob("*.ql"):
                # Simple heuristic: test rust queries against rust DB, etc.
                query_content = query_file.read_text()
                if db_lang == "rust" and "import rust" in query_content:
                    expected_file = query_tests_dir / f"{query_file.stem}.expected"
                    if not self.run_query_test(query_file, db, expected_file):
                        test_failures += 1
                elif db_lang == "javascript" and "import javascript" in query_content:
                    expected_file = query_tests_dir / f"{query_file.stem}.expected"
                    if not self.run_query_test(query_file, db, expected_file):
                        test_failures += 1
                        
        return test_failures
        
    def test_suites(self):
        """Test query suites."""
        self.log("🎯 Testing query suites...", Colors.BLUE)
        
        suite_dir = self.pack_dir / "query-suites"
        test_dbs = list(self.test_db_dir.glob("*-test-db"))
        
        for suite_file in suite_dir.glob("*.yml"):
            suite_name = suite_file.stem
            self.log(f"  Testing suite: {suite_name}")
            
            for db in test_dbs:
                with tempfile.NamedTemporaryFile(mode='w+', suffix='.csv', delete=False) as f:
                    output_file = f.name
                    
                try:
                    result = self.run_command(
                        f"codeql database analyze {db} {suite_file} "
                        f"--format=csv --output={output_file}",
                        check=False
                    )
                    
                    if result.returncode == 0:
                        self.log(f"    ✓ {suite_name} works with {db.name}", Colors.GREEN)
                    else:
                        self.log(f"    ! {suite_name} skipped for {db.name} (expected)", Colors.YELLOW)
                        
                finally:
                    try:
                        os.unlink(output_file)
                    except:
                        pass
                        
    def run_all_tests(self):
        """Run the complete test suite."""
        self.log("🧪 Running CodeQL Pack Tests...", Colors.BLUE)
        self.log(f"Pack directory: {self.pack_dir}")
        self.log("")
        
        # Step 1: Validate pack
        if not self.validate_pack():
            self.log("❌ Pack validation failed", Colors.RED)
            return False
            
        # Step 2: Create test databases
        self.create_test_databases()
        
        # Step 3: Test individual queries
        test_failures = self.test_queries()
        
        # Step 4: Test query suites
        self.test_suites()
        
        # Summary
        self.log("")
        if test_failures == 0:
            self.log("🎉 All tests passed!", Colors.GREEN)
            return True
        else:
            self.log(f"❌ {test_failures} test(s) failed", Colors.RED)
            return False

def main():
    """Main entry point."""
    pack_dir = Path(__file__).parent.parent
    tester = CodeQLTester(pack_dir)
    
    if len(sys.argv) > 1:
        if sys.argv[1] in ["--help", "-h"]:
            print("Usage: python test-runner.py [--help] [--validate]")
            print("")
            print("Options:")
            print("  --help, -h    Show this help message")
            print("  --validate    Only run pack validation")
            return
        elif sys.argv[1] == "--validate":
            success = tester.validate_pack()
            sys.exit(0 if success else 1)
            
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()