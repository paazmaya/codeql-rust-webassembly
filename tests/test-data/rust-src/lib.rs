use wasm_bindgen::prelude::*;

// Test case for UnsafeWasmCode.ql - should be flagged
#[wasm_bindgen]
pub fn unsafe_memory_access(ptr: *mut u8, len: usize) -> i32 {
    unsafe {
        // This unsafe block in a WASM-exported function should trigger the query
        *ptr = 42;
        std::slice::from_raw_parts_mut(ptr, len)[0] as i32
    }
}

// Test case - should NOT be flagged (no unsafe block)
#[wasm_bindgen]
pub fn safe_function(x: i32) -> i32 {
    x * 2
}

// Test case - should NOT be flagged (unsafe but not WASM-exported)
fn internal_unsafe_function() {
    unsafe {
        // This shouldn't trigger since it's not exported to WASM
        let ptr = std::ptr::null_mut::<u8>();
        *ptr = 0;
    }
}

// Test case for error handling - should be flagged
#[wasm_bindgen]
pub fn parse_number(input: &str) -> Result<i32, String> {
    // This returns Result but query should check for proper error handling
    input.parse().map_err(|e| e.to_string())
}

// Another unsafe WASM export - should be flagged
#[wasm_bindgen]
pub fn manipulate_array(data: &mut [u8]) {
    unsafe {
        // Direct memory manipulation in WASM export
        let ptr = data.as_mut_ptr();
        *ptr.offset(0) = 255;
    }
}