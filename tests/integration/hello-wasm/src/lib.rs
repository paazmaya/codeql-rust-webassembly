use wasm_bindgen::prelude::*;

// Import the `console.log` function from the browser
#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console)]
    fn log(s: &str);
}

// A macro to provide `println!(..)`-style syntax for `console.log` logging.
macro_rules! console_log {
    ( $( $t:tt )* ) => {
        log(&format!( $( $t )* ))
    }
}

// Safe function - should not trigger queries
#[wasm_bindgen]
pub fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

// Unsafe function that should trigger UnsafeWasmCode query
#[wasm_bindgen]
pub fn unsafe_memory_operation(data: &mut [u8]) -> usize {
    unsafe {
        // This unsafe block should be flagged
        let ptr = data.as_mut_ptr();
        *ptr = 42;
        ptr.offset(1).write(255);
    }
    data.len()
}

// Function with Result return type for error handling test
#[wasm_bindgen]
pub fn parse_and_double(input: &str) -> Result<i32, String> {
    match input.parse::<i32>() {
        Ok(num) => Ok(num * 2),
        Err(_) => Err("Invalid number".to_string()),
    }
}

// Another unsafe operation
#[wasm_bindgen]
pub fn raw_pointer_access(offset: usize) -> u8 {
    unsafe {
        // Dangerous pointer arithmetic
        let base_ptr = 0x1000 as *const u8;
        *base_ptr.offset(offset as isize)
    }
}

// Safe utility function
#[wasm_bindgen]
pub fn fibonacci(n: u32) -> u32 {
    match n {
        0 => 0,
        1 => 1,
        _ => fibonacci(n - 1) + fibonacci(n - 2),
    }
}