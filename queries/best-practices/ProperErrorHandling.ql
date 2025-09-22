/**
 * @name Proper error handling in WASM bindings
 * @description Ensures WebAssembly functions properly handle and propagate errors
 * @kind problem
 * @problem.severity warning
 * @precision medium
 * @id rust-wasm/error-handling
 * @tags maintainability
 *       rust
 *       webassembly
 *       error-handling
 */

import rust

from Function f
where 
  f.hasAttribute("wasm_bindgen") and
  f.getReturnType().toString().matches("%Result%") and
  not exists(ExprStmt stmt | 
    stmt.getParent*() = f and
    stmt.getExpr().toString().matches("%unwrap%")
  )
select f, "WebAssembly function returns Result but may not handle errors properly"