/**
 * @name Missing input validation at WASM boundary
 * @description JavaScript inputs to WebAssembly functions should be validated
 * @kind problem
 * @problem.severity error
 * @security-severity 8.0
 * @precision high
 * @id js-wasm/missing-input-validation
 * @tags security
 *       javascript
 *       webassembly
 *       input-validation
 */

import javascript

from CallExpr call, PropAccess wasmCall
where 
  // Call to a WASM function
  wasmCall = call.getCallee() and
  wasmCall.getPropertyName().matches("%wasm%") and
  // No validation of arguments
  not exists(IfStmt validation |
    validation.getParent*() = call.getParent() and
    validation.getTest().getAChild*() = call.getAnArgument()
  )
select call, "WebAssembly function call lacks input validation for argument: " + call.getAnArgument()