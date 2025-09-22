/**
 * @name Unsafe Rust code in WebAssembly context
 * @description Identifies unsafe Rust code blocks that could lead to memory safety issues in WebAssembly
 * @kind problem
 * @problem.severity warning
 * @security-severity 7.0
 * @precision medium
 * @id rust-wasm/unsafe-code
 * @tags security
 *       rust
 *       webassembly
 *       memory-safety
 */

import rust

from UnsafeBlock unsafe
where 
  // Focus on unsafe blocks that could affect WASM exports
  exists(Function f | 
    f.getAChild*() = unsafe and 
    f.hasAttribute("wasm_bindgen")
  )
select unsafe, "Unsafe code block in WebAssembly-exported function may lead to memory safety issues"