import init, { 
    greet, 
    unsafe_memory_operation, 
    parse_and_double, 
    raw_pointer_access, 
    fibonacci 
} from './pkg/hello_wasm.js';

async function run() {
    // Initialize the WASM module
    await init();

    // Safe call - should not trigger queries
    const greeting = greet("WebAssembly");
    console.log(greeting);

    // Unsafe call without validation - should trigger MissingWasmInputValidation
    const userInput = document.getElementById('user-input')?.value || "invalid";
    try {
        const result = parse_and_double(userInput);
        console.log("Parsed result:", result);
    } catch (e) {
        console.error("Parse error:", e);
    }

    // Large data transfer - should trigger InefficientDataTransfer
    const largeBuffer = new Uint8Array(10000);
    for (let i = 0; i < largeBuffer.length; i++) {
        largeBuffer[i] = i % 256;
    }
    const size = unsafe_memory_operation(largeBuffer);
    console.log("Processed buffer size:", size);

    // Direct pointer access without validation - should trigger validation query
    const randomOffset = Math.floor(Math.random() * 1000);
    try {
        const value = raw_pointer_access(randomOffset);
        console.log("Memory value:", value);
    } catch (e) {
        console.error("Memory access error:", e);
    }

    // Performance test with large computation
    const fibResult = fibonacci(40);
    console.log("Fibonacci result:", fibResult);
}

// Event handlers that call WASM without validation
document.addEventListener('DOMContentLoaded', () => {
    run();

    // Button click handler - should trigger validation query
    document.getElementById('process-btn')?.addEventListener('click', (event) => {
        const input = event.target.dataset.value;
        // No validation before WASM call
        const result = parse_and_double(input);
        console.log(result);
    });

    // Input handler with large data - should trigger performance query
    document.getElementById('data-input')?.addEventListener('change', (event) => {
        const data = new Array(5000).fill(0).map((_, i) => i);
        // Large array passed directly to WASM
        const processed = unsafe_memory_operation(new Uint8Array(data));
        console.log("Processed:", processed);
    });
});

// Utility function that validates input - should NOT trigger queries
function safeParseAndDouble(input) {
    if (typeof input !== 'string' || input.trim() === '') {
        throw new Error('Invalid input: must be a non-empty string');
    }
    
    const parsed = parseFloat(input);
    if (isNaN(parsed)) {
        throw new Error('Invalid input: not a number');
    }
    
    return parse_and_double(input);
}