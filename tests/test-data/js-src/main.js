// Test cases for JavaScript WASM interaction queries

// Test case for MissingWasmInputValidation.ql - should be flagged
async function loadAndUseWasm() {
    const wasm = await import('./pkg/my_wasm_module.js');
    
    // No input validation - should trigger query
    const userInput = document.getElementById('user-input').value;
    const result = wasm.unsafe_memory_access(userInput, 1024);
    
    // Another case without validation - should trigger
    const data = new Uint8Array(10000);
    wasm.manipulate_array(data);
    
    return result;
}

// Test case for InefficientDataTransfer.ql - should be flagged
function processLargeDataset() {
    const wasm = window.wasmModule;
    
    // Large array transfer - should trigger performance query
    const largeArray = new Array(5000).fill(0).map((_, i) => i);
    return wasm.process_data(largeArray);
}

// Test case - should NOT be flagged (has validation)
function safeWasmCall() {
    const wasm = window.wasmModule;
    const input = getUserInput();
    
    // Input validation present
    if (typeof input !== 'number' || input < 0 || input > 1000) {
        throw new Error('Invalid input');
    }
    
    return wasm.safe_function(input);
}

// Test case - should NOT be flagged (small data transfer)
function efficientWasmCall() {
    const wasm = window.wasmModule;
    const smallArray = [1, 2, 3, 4, 5];
    return wasm.process_small_data(smallArray);
}

// Another validation missing case - should be flagged
class WasmProcessor {
    constructor(wasmModule) {
        this.wasm = wasmModule;
    }
    
    processUserData(rawData) {
        // Direct WASM call without validation - should trigger
        return this.wasm.parse_number(rawData);
    }
}

// Edge case: WASM call in callback - should be flagged
function setupEventHandler() {
    document.addEventListener('click', (event) => {
        const wasmInstance = getWasmInstance();
        // No validation of event data - should trigger
        wasmInstance.handle_event(event.clientX, event.clientY);
    });
}